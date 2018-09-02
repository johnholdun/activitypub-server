class StatusRoute < Route
  def call
    account =
      FetchAccount.call("#{BASE_URL}/users/#{request.params['username']}")

    return not_found unless account

    status =
      STORAGE.read \
        :statuses,
        "#{account['id']}/statuses/#{request.params['id']}"

    return not_found unless status

    # TODO: Redirect to original if reblog

    headers['Content-Type'] = 'application/activity+json'

    finish_json(LD_CONTEXT.merge(status))
  end
end
