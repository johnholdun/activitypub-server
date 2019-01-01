class ReadInboxRoute < Route
  LIMIT = 20

  def call
    @account =
      DB[:actors].where(id: "#{BASE_URL}/users/#{request.params['username']}").first

    return not_found unless @account

    unless request['headers']['Authorization'] == "Bearer #{@account[:auth_token]}"
      return finish('Not authorized', 401)
    end

    @account = Oj.load(@account[:json])

    headers['Content-Type'] = 'application/activity+json'

    if request.params['cursor']
      activities = fetch_activities(request.params)

      min_cursor = all_activities.order(:id).select(:id).first[:id]
      max_cursor = all_activities.reverse(:id).select(:id).first[:id]

      next_cursor =
        if activities.size > 0
          if activities.first[:id] < max_cursor
            activities.first[:id]
          end
        elsif request.params['cursor'] =~ /^-/
          request.params['cursor'].to_i.abs
        end

      prev_cursor =
        if activities.size > 0
          if activities.last[:id] > min_cursor
            "-#{activities.last[:id]}"
          end
        elsif request.params['cursor'] !~ /^-/
          "-#{request.params['cursor'].to_i}"
        end

      finish_json \
        LD_CONTEXT.merge \
          id: account_inbox_url(cursor: request.params['cursor']),
          type: 'OrderedCollectionPage',
          totalItems: all_activities.count,
          next: (account_inbox_url(cursor: next_cursor) if next_cursor),
          prev: (account_inbox_url(cursor: prev_cursor) if prev_cursor),
          partOf: account_inbox_url,
          orderedItems: items(activities)
    else
      finish_json \
        LD_CONTEXT.merge \
          id: account_inbox_url,
          type: 'CollectionPage',
          totalItems: all_activities.count,
          first: account_inbox_url(cursor: '0'),
          last: account_inbox_url(cursor: '-0')
    end
  end

  private

  def account_inbox_url(params = {})
    path = @account['inbox']
    params.size > 0 ? "#{path}?#{to_query(params)}" : path
  end

  def to_query(params)
    params.map { |k, v| "#{k}=#{v}" }.join('&')
  end

  def all_activities
    @all_activities ||= DB[:inbox].where(actor: @account['id'])
  end

  def fetch_activities(params)
    query = all_activities.limit(LIMIT)

    cursor = params['cursor']

    if cursor == '0'
      query = query.order(:id)
    elsif cursor == '-0'
      query = query.reverse(:id)
    elsif cursor =~ /^-/
      query = query.reverse(:id).where { id < cursor.to_i.abs }
    else
      query = query.order(:id).where { id > cursor.to_i }
    end

    query.to_a.sort_by { |a| a[:id] }.reverse
  end

  def items(inbox)
    activity_ids = inbox.map { |i| i[:activity] }

    activities =
      DB[:activities]
        .where(id: activity_ids)
        .to_a
        .sort_by { |a| activity_ids.index(a[:id]) }
        .map { |a| Oj.load(a[:json]) }

    object_ids =
      activities
        .map { |a| a['object'] }
        .select { |o| o.is_a?(String) }

    objects =
      DB[:objects]
        .where(id: object_ids)
        .to_a
        .map { |o| [o[:id], Oj.load(o[:json])] }
        .to_h

    activities.map do |activity|
      object = activity['object']
      activity.merge('object' => objects[object] || object)
    end
  end
end
