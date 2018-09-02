require './lib/service'

class FollowAccepter < Service
  attribute :account_id
  attribute :item_id

  def call
    account = STORAGE.read(:accounts, account_id)
    item = STORAGE.read(:incomingItems, item_id)
    follower = STORAGE.read(:accounts, item['actor'])

    Deliverer.call \
      account,
      [follower['inbox']],
      id: nil,
      type: 'Accept',
      actor: account['id'],
      object: item
  end
end
