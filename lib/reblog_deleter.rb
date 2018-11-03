require './lib/service'

class ReblogDeleter < Service
  attribute :account_uri
  attribute :status_uri

  def call
    # TODO: don't delete reblog if it doesn't exist
    # TODO: remove from local timeline

    account = Oj.load(DB[:actors].where(id: account_uri).first[:json])
    status = FetchStatus.call(status_uri)
    author = FetchAccount.call(status['attributedTo'])

    inbox_urls = [(author['endpoints'] || {})['sharedInbox'] || author['inbox']]
    inbox_urls +=
      DB[:follows].where(object: account['id']).map(:actor).map do |id|
        follower = DB[:actors].where(id: id).first
        follower = Oj.load(follower[:json]) if follower
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
