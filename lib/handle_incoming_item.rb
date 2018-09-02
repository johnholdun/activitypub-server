class HandleIncomingItem
  TABLES = {
    'Follow' => :followers,
    'Like' => :favorites
  }

  def initialize(account_id, item_id)
    @account_id = account_id
    @item_id = item_id
  end

  def call
    result =
      case item['type']
      when 'Follow'
        if item['object'] == account['id']
          STORAGE.append(:followers, account['id'], item['actor'])
          # Make sure we have a local copy of this person
          FetchAccount.call(item['actor'])
          FollowAccepter.call(account_id: account['id'], item_id: item['id'])
        end
      when 'Like'
        status = STORAGE.read(:statuses, item['object'])
        if status && status['attributedTo'] == account['id']
          STORAGE.append(:favorites, status['id'], item['actor'])
        end
      when 'Accept'
        if item['object']['type'] == 'Follow' && item['object']['actor'] == account['id']
          STORAGE.append(:following, account['id'], item['object']['object'])
        end
      when 'Undo'
        case item['object']['type']
        when 'Follow'
          if item['object']['object'] == account['id']
            STORAGE.remove \
              TABLES[item['object']['type']],
              account['id'],
              item['object']['actor']
          end
        when 'Like'
          status = STORAGE.read(:statuses, item['object'])
          if status && status['attributedTo'] == account['id']
            STORAGE.remove(:favorites, status['id'], item['actor'])
          end
        end
      end

    puts "Handled incoming item\n#{account['id']}\n#{item['id']}\n#{result.inspect}"
  end

  def self.call(*args)
    new(*args).call
  end

  private

  attr_reader :account_id, :item_id

  def account
    @account ||= STORAGE.read(:accounts, account_id)
  end

  def item
    @item ||= STORAGE.read(:incomingItems, item_id)
  end
end
