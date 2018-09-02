require './lib/service'

class StatusDeleter < Service
  attribute :account_uri
  attribute :status_uri

  def call
    # TODO: don't delete if status doesn't exist

    account = STORAGE.read(:accounts, account_id)
    status = STORAGE.read(:statuses, status_uri)

    raise 'invalid account' unless account
    raise 'invalid status' unless status
    raise 'wrong author' unless status['attributedTo'] == account['id']

    mentions = status['tag'].map { |t| FetchAccount.call(t['href']) }

    inbox_urls =
      mentions.map { |m| (m['endpoints'] || {})['sharedInbox'] || m['inbox'] }
    inbox_urls +=
      STORAGE.read(:followers, account['id']).map do |id|
        follower = STORAGE.read(:accounts, id)
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
