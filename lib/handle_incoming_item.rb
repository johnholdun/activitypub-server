class HandleIncomingItem
  def initialize(account, activity, object)
    @account = account
    @activity = activity
    @object = object
  end

  def call
    result =
      case activity['type']
      when 'Follow'
        if object == account['id']
          STORAGE.append(:followers, account['id'], activity['actor'])
          # Make sure we have a local copy of this person
          FetchAccount.call(activity['actor'])
          FollowAccepter.call(account_id: account['id'], activity: activity)
        end
      when 'Accept'
        # TODO: Make sure we actually sent a follow request to this person
        if object['type'] == 'Follow' && object['actor'] == account['id']
          STORAGE.append(:following, account['id'], object['object'])
        end
      when 'Undo'
        if object['type'] == 'Follow' && object['object'] == account['id']
          STORAGE.remove \
            :followers,
            account['id'],
            object['actor']
        end
      end

    puts "Handled incoming activity\n#{account['id']}\n#{activity['id']}\n#{result.inspect}"
  end

  def self.call(*args)
    new(*args).call
  end

  private

  attr_reader :account, :activity, :object
end
