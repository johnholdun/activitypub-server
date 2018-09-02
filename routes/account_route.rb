class AccountRoute < Route
  PAGE_SIZE = 20

  def call
    account =
      FetchAccount.call("#{BASE_URL}/users/#{request.params['username']}")

    return not_found unless account

    headers['Link'] =
      LinkHeader.new(
        [
          [
            "/.well-known/webfinger?resource=acct:#{account['username']}@#{account['domain']}",
            [%w(rel lrdd), %w(type application/xrd+xml)],
          ],
          [
            account['id'],
            [%w(rel alternate), %w(type application/activity+json)],
          ],
        ]
      ).to_s

    headers['Content-Type'] = 'application/activity+json'

    finish_json(LD_CONTEXT.merge(account))
  end
end
