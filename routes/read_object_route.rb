class ReadObjectRoute < Route
  def call
    # TODO: check audience, authentication?
    id =
      [
        BASE_URL,
        'users',
        request.params['username'],
        TYPE_PARAMS[request.params['type']],
        request.params['id']
      ]
        .join('/')

    object = DB[:objects].where(id: id).first

    return not_found unless object

    headers['Content-Type'] = 'application/activity+json'

    finish_json \
      LD_CONTEXT.merge \
        Oj
          .parse(object[:json])
          .reject { |k, _| %w(bto bcc).include?(k) }
  end
end
