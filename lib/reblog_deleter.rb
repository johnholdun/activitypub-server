require './lib/service'

class ReblogDeleter < Service
  attribute :account_uri
  attribute :status_uri

  def call
    # TODO: don't delete favorite if it doesn't exist
    # TODO: remove from local timeline

    account = STORAGE.read(:accounts, account_uri)
    status = FetchStatus.call(status_uri)
    author = FetchAccount.call(status['attributedTo'])

    inbox_urls = [(author['endpoints'] || {})['sharedInbox'] || author['inbox']]
    inbox_urls +=
      STORAGE.read(:followers, account['id']).map do |id|
        follower = STORAGE.read(:accounts, id)
        (follower['endpoints'] || {})['sharedInbox'] || follower['inbox']
      end

    Deliverer.call \
      account,
      inbox_urls.uniq,
      id: "#{account['id']}#announces/#{status['id']}/undo",
      type: 'Undo',
      actor: account['id'],
      to: [PUBLIC],
      cc: [status['attributedTo'], account['followers']],
      object: "#{account['id']}#announces/#{status['id']}"
  end
end
