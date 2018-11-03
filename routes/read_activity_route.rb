class ReadActivityRoute < Route
  def call
    # TODO: check audience, authentication?
    activity =
      STORAGE.read \
        :activities,
        "#{BASE_URL}/users/#{request.params['username']}/activities/#{request.params['id']}"

    return not_found unless activity

    headers['Content-Type'] = 'application/activity+json'

    finish_json(activity.reject { |k, _| %w(bto bcc).include?(k) })
  end
end
