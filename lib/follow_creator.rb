require './lib/service'

class FollowCreator < Service
  attribute :account_id
  attribute :target_account_id

  def call
    # TODO: validate uri
    # TODO: check for existing blocks in either direction

    account = DB[:actors].where(id: account_id).first

    raise 'no account' unless account

    account = Oj.load(account[:json])

    target = FetchAccount.call(target_account_id)

    raise 'whomst is this' unless target

    raise 'cannot follow yourself' if account['id'] == target['id']

    Deliverer.call \
      account,
      [target['inbox']],
      id: nil,
      type: 'Follow',
      actor: account['id'],
      object: target['id']
  end
end
