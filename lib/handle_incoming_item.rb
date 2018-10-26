class HandleIncomingItem
  TABLES = {
    'Follow' => :followers,
    'Like' => :favorites
  }

  def initialize(account, item, received_at)
    @account = account
    @item = item
    @received_at = received_at
  end

  def call
    result =
      case item['type']
      when 'Follow'
        if item['object'] == account['id']
          STORAGE.append(:followers, account['id'], item['actor'])
          # Make sure we have a local copy of this person
          FetchAccount.call(item['actor'])
          FollowAccepter.call(account_id: account['id'], item: item)
          save_notification('follows')
        end
      when 'Like'
        status = STORAGE.read(:statuses, item['object'])
        if status && status['attributedTo'] == account['id']
          save_notification('likes')
        end
      when 'Accept'
        if item['object']['type'] == 'Follow' && item['object']['actor'] == account['id']
          STORAGE.append(:following, account['id'], item['object']['object'])
          save_notification('follow-accepts')
        end
      when 'Undo'
        case item['object']['type']
        when 'Follow'
          if item['object']['object'] == account['id']
            STORAGE.remove \
              TABLES[item['object']['type']],
              account['id'],
              item['object']['actor']
            save_notification('unfollows')
          end
        when 'Like'
          status = STORAGE.read(:statuses, item['object'])
          if status && status['attributedTo'] == account['id']
            save_notification('unlikes')
          end
        when 'Announce'
          # TODO: we're not capturing this, check that the object is as expected
          status = STORAGE.read(:statuses, item['object'])
          if status && status['attributedTo'] == account['id']
            save_notification('unreblogs')
          end
        end
      when 'Create'
        if item['object'].is_a?(Hash) && item['object']['type'] == 'Note' && item['object']['attributedTo'] == item['actor']
          STORAGE.write(:statuses, item['object']['id'], item['object'])
        else
          puts "create? idk!\n#{JSON.pretty_generate(item)}"
          raise 'unexpected create thing'
        end
      when 'Announce'
        status = STORAGE.read(:statuses, item['object'])
        if status && status['attributedTo'] == account['id']
          save_notification('reblogs')
        else
          # TODO: this is a reblog of someone else; add it to the timeline
        end
      else
        puts "idk!\n#{JSON.pretty_generate(item)}"
          raise 'unexpected thing'
      end

    puts "Handled incoming item\n#{account['id']}\n#{item['id']}\n#{result.inspect}"
  end

  def self.call(*args)
    new(*args).call
  end

  private

  attr_reader :account, :item, :received_at

  def save_notification(type)
    STORAGE.append \
      :notifications,
      account['id'],
      type: type,
      item: item.reject { |k, _| %w(@context signature).include?(k) },
      received_at: received_at
  end
end
