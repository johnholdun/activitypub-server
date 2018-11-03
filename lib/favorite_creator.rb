require './lib/service'

class FavoriteCreator < Service
  attribute :account_uri
  attribute :status_uri

  def call
    # TODO: don't create favorite if already faved

    account = Oj.load(DB[:actors].where(id: account_uri).first[:json])
    status = FetchStatus.call(status_uri)
    author = FetchAccount.call(status['attributedTo'])

    Deliverer.call \
      account,
      [author['inbox']],
      id: "#{account['id']}#likes/#{status['id']}",
      type: 'Like',
      actor: account['id'],
      object: status['id']
  end
end
