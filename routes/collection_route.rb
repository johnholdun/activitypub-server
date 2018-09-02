class CollectionRoute < Route
  def call
    return not_found unless request.params['id'] == 'featured'

    account =
      FetchAccount.call("#{BASE_URL}/users/#{request.params['username']}")

    return not_found unless account

    # TODO: Return pinned statuses
    statuses = []

    headers['Content-Type'] = 'application/activity+json'

    finish_json \
      LD_CONTEXT.merge \
        id: request.url,
        type: 'OrderedCollection',
        totalItems: statuses.size,
        orderedItems: statuses
  end
end
