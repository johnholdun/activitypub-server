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
          params = { actor: activity['actor'], object: account['id'] }
          existing = DB[:follows].where(params)
          if existing.count.zero?
            DB[:follows].insert(params.merge(accepted: true))
          end
          # Make sure we have a local copy of this person
          FetchAccount.call(activity['actor'])
          FollowAccepter.call(account_id: account['id'], activity: activity)
        end
      when 'Accept'
        DB[:follows]
          .where(actor: account['id'], object: object['actor'])
          .update(accepted: true)
      when 'Undo'
        if object['type'] == 'Follow' && object['object'] == account['id']
          DB[:follows].where(actor: object['actor'], object: account['id']).delete
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
