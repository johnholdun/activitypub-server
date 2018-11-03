require './lib/service'

class FollowAccepter < Service
  attribute :account_id
  attribute :activity

  def call
    account = Oj.load(DB[:actors].where(id: account_id).first[:json])
    follower = Oj.load(DB[:actors].where(id: activity['actor']).first[:json])

    Deliverer.call \
      account,
      [follower['inbox']],
      id: nil,
      type: 'Accept',
      actor: account['id'],
      object: activity
  end
end
