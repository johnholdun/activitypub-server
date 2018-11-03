class ReadObjectRoute < Route
  def call
    # TODO: check audience, authentication?
    object =
      DB[:objects]
        .where(id: "#{BASE_URL}/users/#{request.params['username']}/objects/#{request.params['id']}")
        .first

    return not_found unless object

    headers['Content-Type'] = 'application/activity+json'

    finish_json(object[:json].reject { |k, _| %w(bto bcc).include?(k) })
  end
end
