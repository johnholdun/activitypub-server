class CreateOutboxRoute < Route
  def call
    account =
      DB[:actors].where(id: "#{BASE_URL}/users/#{request.params['username']}").first

    return not_found unless account

    unless request['headers']['Authorization'] == "Bearer #{account[:auth_token]}"
      return finish('Not authorized', 401)
    end

    account = Oj.load(account[:json])

    request.body.rewind
    body = request.body.read.force_encoding('UTF-8')
    activity = Oj.load(body, mode: :strict)
    object = activity['object']

    unless ACTIVITY_TYPES.include?(activity['type'])
      object =
        activity.merge \
          'id' => "#{account['id']}/activities/#{(Time.now.to_f * 1000).round}",
          'attributedTo' => account['id']

      activity =
        {
          '@context' => 'https://www.w3.org/ns/activitystreams',
          'type' => 'Create',
          'id' => "#{account['id']}/create/TODO/#{(Time.now.to_f * 1000).round}",
          'actor' => account['id'],
          'object' => object,
          'to' => activity['to'],
          'cc' => activity['cc']
        }
    end

    timestamp = (Time.now.to_f * 1000).round
    activity['id'] = "#{account['id']}/activities/#{timestamp}"

    activity['published'] = Time.now.utc.iso8601

    if activity['type'] == 'Create'
      object['published'] = activity['published']
      object['id'] = "#{account['id']}/#{TYPE_PARAMS[object['type']]}/#{timestamp}"
    end

    # TODO: fetch object if not owned by this origin
    if object.is_a?(Hash)
      existing = DB[:objects].where(id: object['id'])

      if existing.count > 0
        new_json = Oj.load(existing.first[:json]).merge(object).reject { |_, v| v.nil? }
        existing.update(json: new_json.to_json)
      else
        DB[:objects].insert \
          id: object['id'],
          type: object['type'],
          published: object['published'],
          json: object.to_json
      end

      activity['object'] = object['id']
    end

    activity['actor'] = account['id']

    DB[:activities].insert \
      id: activity['id'],
      type: activity['type'],
      actor: activity['actor'],
      object: activity['object'],
      target: activity['target'],
      published: activity['published'],
      json: activity.to_json

    headers['Location'] = activity['id']
    return finish(nil, 201)

    # TODO: Handle deliveries asynchronously

    # begin
    #   StatusCreator.call \
    #     account_id: account_id,
    #     text: text,
    #     in_reply_to: in_reply_to,
    #     sensitive: sensitive,
    #     summary: summary

    #   finish_json \
    #     data: {
    #       type: 'statuses',
    #       accountId: account_id,
    #       text: text,
    #       inReplyTo: in_reply_to,
    #       sensitive: sensitive,
    #       summary: summary,
    #     }
    # rescue => e
    #   finish_json(errors: [e.to_s], status: 500)
    # end
  end
end
