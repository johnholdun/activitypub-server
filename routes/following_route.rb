class FollowingRoute < Route
  PAGE_SIZE = 50

  def call
    @account =
      FetchAccount.call("#{BASE_URL}/users/#{request.params['username']}")

    return not_found unless @account

    headers['Content-Type'] = 'application/activity+json'

    page = request.params['page'].to_i

    all_following = STORAGE.read(:following, @account['id']) || []

    if page > 0
      following = all_following[(page - 1) * PAGE_SIZE, PAGE_SIZE].to_a
      following_next_page = page + 1 if following.size == PAGE_SIZE
      following_prev_page = page - 1 if page > 1

      finish_json \
        LD_CONTEXT.merge \
          id: account_followers_url(page),
          type: 'OrderedCollectionPage',
          totalItems: all_following.size,
          next: (account_followers_url(following_next_page) if following_next_page),
          prev: (account_followers_url(following_prev_page) if following_prev_page),
          partOf: account_followers_url,
          items: following
    else
      finish_json \
        LD_CONTEXT.merge \
          id: account_followers_url,
          type: 'OrderedCollection',
          totalItems: all_following.size,
          first: account_followers_url(1)
    end
  end

  private

  def account_followers_url(page = nil)
    path = @account['following']
    page ? "#{path}?page=#{page}" : path
  end
end
