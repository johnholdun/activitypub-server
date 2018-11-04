class FollowingRoute < Route
  PAGE_SIZE = 50

  def call
    @account =
      FetchAccount.call("#{BASE_URL}/users/#{request.params['username']}")

    return not_found unless @account

    headers['Content-Type'] = 'application/activity+json'

    page = request.params['page'].to_i

    following = DB[:follows].where(actor: @account['id'])

    total_following = following.count

    if page > 0
      following =
        following
        .limit(PAGE_SIZE + 1)
        .offset((page - 1) * PAGE_SIZE)
        .map(:object)

      following_next_page = page + 1 if following.count > PAGE_SIZE
      following_prev_page = page - 1 if page > 1

      finish_json \
        LD_CONTEXT.merge \
          id: account_following_url(page),
          type: 'OrderedCollectionPage',
          totalItems: total_following,
          next: (account_following_url(following_next_page) if following_next_page),
          prev: (account_following_url(following_prev_page) if following_prev_page),
          partOf: account_following_url,
          items: following[0, PAGE_SIZE]
    else
      finish_json \
        LD_CONTEXT.merge \
          id: account_following_url,
          type: 'OrderedCollection',
          totalItems: total_following,
          first: account_following_url(1)
    end
  end

  private

  def account_following_url(page = nil)
    path = @account['following']
    page ? "#{path}?page=#{page}" : path
  end
end
