require './lib/service'

class ReblogCreator < Service
  attribute :account_uri
  attribute :status_uri

  def call
    # TODO: don't create reblog if exists
    # TODO: add reblog to local storage

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
      id: "#{account['id']}#announces/#{status['id']}",
      type: 'Announce',
      actor: account['id'],
      published: Time.now.iso8601,
      to: [PUBLIC],
      cc: [status['attributedTo'], account['followers']],
      object: status['id']
  end
end
