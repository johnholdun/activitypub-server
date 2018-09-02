require './lib/service'

class FavoriteDeleter < Service
  attribute :account_uri
  attribute :status_uri

  def call
    # TODO: don't delete favorite if it doesn't exist

    account = STORAGE.read(:accounts, account_uri)

    raise 'invalid account' unless account

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
