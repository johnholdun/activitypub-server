require './lib/service'

class ReblogCreator < Service
  attribute :account_uri
  attribute :status_uri

  def call
    # TODO: don't create reblog if exists
    # TODO: add reblog to local storage

    account = Oj.load(DB[:actors].where(id: account_uri).first[:json])
    status = FetchStatus.call(status_uri)
    author = FetchAccount.call(status['attributedTo'])

    inbox_urls = [(author['endpoints'] || {})['sharedInbox'] || author['inbox']]
    inbox_urls +=
      DB[:follows].where(target: account['id']).map(:actor).map do |id|
        follower = DB[:actors].where(id: id).first
        follower = Oj.load(follower[:json]) if follower
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
