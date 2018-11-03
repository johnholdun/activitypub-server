require './lib/service'

class FollowAccepter < Service
  attribute :account_id
  attribute :activity

  def call
    account = STORAGE.read(:accounts, account_id)
    follower = STORAGE.read(:accounts, activity['actor'])

    Deliverer.call \
      account,
      [follower['inbox']],
      id: nil,
      type: 'Accept',
      actor: account['id'],
      object: activity
  end
end
