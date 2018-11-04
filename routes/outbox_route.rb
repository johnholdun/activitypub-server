class OutboxRoute < Route
  LIMIT = 20

  def call
    @account =
      FetchAccount.call("#{BASE_URL}/users/#{request.params['username']}")

    return not_found unless @account

    headers['Content-Type'] = 'application/activity+json'

    if request.params['page'] == 'true'
      # TODO: filter by min_id, max_id, since_id, and limit
      statuses = all_statuses.to_a

      next_page =
        if statuses.count == LIMIT
          account_outbox_url(page: true, max_id: URI.escape(statuses.last[:id]))
        end

      prev_page =
        unless statuses.count == 0
          account_outbox_url(page: true, min_id: URI.escape(statuses.first[:id]))
        end

      id_url_params =
        {
          page: true,
          max_id: request.params['max_id'],
          min_id: request.params['min_id']
        }.compact

      finish_json \
        LD_CONTEXT.merge \
          id: account_outbox_url(id_url_params),
          type: 'OrderedCollectionPage',
          totalItems: all_statuses.count,
          next: next_page,
          prev: prev_page,
          partOf: account_outbox_url,
          orderedItems: statuses.map { |s| Oj.load(s[:json]) }
    else
      finish_json \
        LD_CONTEXT.merge \
          id: account_outbox_url,
          type: 'CollectionPage',
          totalItems: all_statuses.count,
          first: account_outbox_url(page: true),
          last: account_outbox_url(page: true, min_id: 0)
    end
  end

  private

  def account_outbox_url(params = {})
    path = @account['outbox']
    params.size > 0 ? "#{path}?#{to_query(params)}" : path
  end

  def to_query(params)
    params.map { |k, v| "#{k}=#{v}" }.join('&')
  end

  def all_statuses
    @all_statuses ||=
      DB[:activities].where(actor: @account['id']).reverse(:published)
  end
end
