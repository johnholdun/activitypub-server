class ReadInboxRoute < Route
  LIMIT = 20

  def call
    # TODO: Authentication

    @account =
      FetchAccount.call("#{BASE_URL}/users/#{request.params['username']}")

    return not_found unless @account

    headers['Content-Type'] = 'application/activity+json'

    if request.params['page'] == 'true'
      activities = fetch_activities(request.params.symbolize_keys)

      next_page =
        if activities.size > LIMIT
          account_inbox_url(page: true, min_id: activities[-2]['id'])
        end

      prev_page =
        unless activities.size == 0
          account_inbox_url(page: true, max_id: activities.first['id'])
        end

      # TODO: Use cursors instead of IDs
      id_url_params =
        {
          page: true,
          max_id: request.params['max_id'],
          min_id: request.params['min_id']
        }.compact

      finish_json \
        LD_CONTEXT.merge \
          id: account_inbox_url(id_url_params),
          type: 'OrderedCollectionPage',
          totalItems: all_activities.size,
          next: next_page,
          prev: prev_page,
          partOf: account_inbox_url,
          orderedItems: items(activities)
    else
      finish_json \
        LD_CONTEXT.merge \
          id: account_inbox_url,
          type: 'CollectionPage',
          totalItems: all_activities.size,
          first: account_inbox_url(page: true),
          last: account_inbox_url(page: true, min_id: 0)
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
    @all_activities ||= DB[:inbox].where(actor: @account['id']).reverse(:id)
  end

  def fetch_activities(params)
    query = all_activities.limit(LIMIT + 1)

    if params[:min_id]
      query = query.where { id >= params[:min_id] }
    elsif params[:max_id]
      query = query.where { id <= params[:max_id] }
    end

    query.to_a
  end

  def items(inbox)
    ids = inbox.map { |i| i[:activity] }

    DB[:activities]
      .where(id: ids)
      .to_a
      .sort_by { |a| ids.index(a[:id]) }
      .map { |a| Oj.load(a[:json]) }
  end
end
