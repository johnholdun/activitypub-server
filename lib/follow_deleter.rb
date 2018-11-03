require './lib/service'

class FollowDeleter < Service
  attribute :account_id
  attribute :target_account_id

  def call
    # TODO: validate uri
    # TODO: ensure existence of follow

    account = DB[:actors].where(id: account_id).first

    raise 'no account' unless account

    account = Oj.load(account)

    target = FetchAccount.call(target_account_id)

    raise 'no target' unless target

    unless STORAGE.read(:following, account['id']).include?(target['id'])
      raise 'not following'
    end

    Deliverer.call \
      account,
      [target['inbox']],
      id: "#{account['id']}#follows/#{target['id']}/undo",
      type: 'Undo',
      actor: account['id'],
      object: {
        id: "#{account['id']}#follows/#{target['id']}",
        type: 'Follow',
        actor: account['id'],
        object: target['id']
      }
  end
end
