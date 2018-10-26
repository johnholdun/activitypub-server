class ReadStatusesRoute < Route
  def call
    # TODO: authentication
    current_account_id = "#{BASE_URL}/users/john"
    # TODO: filtering and pagination
    following = STORAGE.read(:following, current_account_id)
    # TODO: include reblogs
    statuses =
      STORAGE
        .list(:statuses)
        .select { |s| following.include?(s['attributedTo']) }
        .select { |s| viewable?(s, current_account_id) }
        .sort_by { |s| s['published'] }
        .reverse
    headers['Content-Type'] = 'application/json'
    finish_json(data: statuses)
  end

  private

  def viewable?(status, current_account_id)
    audiences = status['to'].to_a | status['cc'].to_a
    return true if audiences.include?(PUBLIC)
    return true if audiences.include?(current_account_id)
    creator_account = FetchAccount.call(status['attributedTo'])
    return true if creator_account && audiences.include?(creator_account['followers'])
    false
  end
end
