require './lib/service'

class FavoriteDeleter < Service
  attribute :account_uri
  attribute :status_uri

  def call
    # TODO: don't delete favorite if it doesn't exist

    account = DB[:actors].where(id: account_uri).first

    raise 'invalid account' unless account

    account = Oj.load(account[:json])

    status = FetchStatus.call(status_uri)

    raise 'status does not exist' unless status

    author = FetchAccount.call(status['attributedTo'])

    Deliverer.call \
      account,
      [author['inbox']],
      id: "#{account['id']}#likes/#{status['id']}/undo",
      type: 'Undo',
      actor: account['id'],
      object: {
        id: "#{account['id']}#likes/#{status['id']}",
        type: 'Like',
        actor: account['id'],
        object: status['id']
      }
  end
end
