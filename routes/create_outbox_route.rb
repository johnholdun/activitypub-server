class CreateOutboxRoute < Route
  def call
    # TODO: authentication
    account =
      FetchAccount.call("#{BASE_URL}/users/#{request.params['username']}")

    return not_found unless account

    request.body.rewind
    body = request.body.read.force_encoding('UTF-8')
    activity = Oj.load(body, mode: :strict)
    object = activity['object']

    unless ActivityPub::ACTIVITY_TYPES.include?(activity['type'])
      object =
        activity.merge \
          'id' => "#{account['id']}/create/TODO/#{Time.now.to_i}",
          'attributedTo' => account['id'],
          'published' => Time.now.utc.iso8601

      activity =
        {
          '@context' => 'https://www.w3.org/ns/activitystreams',
          'type' => 'Create',
          'id' => "#{account['id']}/create/TODO/#{Time.now.to_i}",
          'actor' => account['id'],
          'object' => object,
          'published' => Time.now.utc.iso8601,
          'to' => activity['to'],
          'cc' => activity['cc']
        }
    end

    timestamp = Time.now.to_i
    activity['id'] = "#{account['id']}/activities/TODO-#{activity['type']}-#{timestamp}"

    if activity['type'] == 'Create'
      object['id'] = "#{account['id']}/objects/TODO-#{object['type']}-#{timestamp}"
    end

    STORAGE.write(:activities, activity['id'], activity)
    # TODO: fetch object if not owned by this origin
    if object.is_a?(Hash)
      # TODO: handle updates as partial rewrites, including null values (which
      # remove key)
      STORAGE.write(:objects, object['id'], object)
    end

    headers['Location'] = activity['id']
    return finish(nil, 201)

    begin
      StatusCreator.call \
        account_id: account_id,
        text: text,
        in_reply_to: in_reply_to,
        sensitive: sensitive,
        summary: summary

      finish_json \
        data: {
          type: 'statuses',
          accountId: account_id,
          text: text,
          inReplyTo: in_reply_to,
          sensitive: sensitive,
          summary: summary,
        }
    rescue => e
      finish_json(errors: [e.to_s], status: 500)
    end
  end
end
