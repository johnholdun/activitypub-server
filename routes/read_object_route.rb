class ReadObjectRoute < Route
  def call
    # TODO: check audience, authentication?
    object =
      STORAGE.read \
        :objects,
        "#{BASE_URL}/users/#{request.params['username']}/objects/#{request.params['id']}"

    return not_found unless object

    headers['Content-Type'] = 'application/activity+json'

    finish_json(object.reject { |k, _| %w(bto bcc).include?(k) })
  end
end
