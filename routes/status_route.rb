class StatusRoute < Route
  def call
    account =
      FetchAccount.call("#{BASE_URL}/users/#{request.params['username']}")

    return not_found unless account

    status =
      DB[:objects]
        .where(id: "#{account['id']}/statuses/#{request.params['id']}")
        .first

    return not_found unless status

    headers['Content-Type'] = 'application/activity+json'

    finish_json(LD_CONTEXT.merge(Oj.load(status[:json])))
  end
end
