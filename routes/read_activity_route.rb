class ReadActivityRoute < Route
  def call
    # TODO: check audience, authentication?
    activity =
      DB[:activities]
        .where(id: "#{BASE_URL}/users/#{request.params['username']}/activities/#{request.params['id']}")
        .first

    return not_found unless activity

    headers['Content-Type'] = 'application/activity+json'

    finish_json(Oj.load(activity[:json]).reject { |k, _| %w(bto bcc).include?(k) })
  end
end
