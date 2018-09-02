class FollowersRoute < Route
  PAGE_SIZE = 50

  def call
    @account =
      FetchAccount.call("#{BASE_URL}/users/#{request.params['username']}")

    return not_found unless @account

    headers['Content-Type'] = 'application/activity+json'

    page = request.params['page'].to_i

    all_followers = STORAGE.read(:followers, @account['id']) || []

    if page > 0
      followers = all_followers[(page - 1) * PAGE_SIZE, PAGE_SIZE].to_a
      followers_next_page = page + 1 if followers.size == PAGE_SIZE
      followers_prev_page = page - 1 if page > 1

      finish_json \
        LD_CONTEXT.merge \
          id: account_followers_url(page),
          type: 'OrderedCollectionPage',
          totalItems: all_followers.size,
          next: (account_followers_url(followers_next_page) if followers_next_page),
          prev: (account_followers_url(followers_prev_page) if followers_prev_page),
          partOf: account_followers_url,
          items: followers
    else
      finish_json \
        LD_CONTEXT.merge \
          id: account_followers_url,
          type: 'OrderedCollection',
          totalItems: all_followers.size,
          first: account_followers_url(1)
    end
  end

  private

  def account_followers_url(page = nil)
    path = @account['followers']
    page ? "#{path}?page=#{page}" : path
  end
end
