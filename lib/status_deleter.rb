require './lib/service'

class StatusDeleter < Service
  attribute :account_id
  attribute :status_uri

  def call
    # TODO: don't delete if status doesn't exist

    account = DB[:actors].where(id: account_id).first
    status = STORAGE.read(:statuses, status_uri)

    raise 'invalid account' unless account
    account = Oj.load(account)
    raise 'invalid status' unless status
    raise 'wrong author' unless status['attributedTo'] == account['id']

    mentions = status['tag'].map { |t| FetchAccount.call(t['href']) }

    inbox_urls =
      mentions.map { |m| (m['endpoints'] || {})['sharedInbox'] || m['inbox'] }
    inbox_urls +=
      DB[:follows].where(object: account['id']).map(:actor).map do |id|
        follower = DB[:actors].where(id: id).first
        follower = Oj.load(follower[:json]) if follower
        (follower['endpoints'] || {})['sharedInbox'] || follower['inbox']
      end

    Deliverer.call \
      account,
      inbox_urls.uniq,
      id: "#{status['id']}#delete",
      type: 'Delete',
      actor: account['id'],
      to: [PUBLIC],
      object: {
        id: status['id'],
        type: 'Tombstone'
      }
  end
end
