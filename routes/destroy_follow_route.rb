class DestroyFollowRoute < Route
  def call
    # TODO: authentication
    account_id = "#{BASE_URL}/users/john"

    request.body.rewind
    body = request.body.read.force_encoding('UTF-8')
    puts "hello #{body.inspect}"
    json = Oj.load(body, mode: :strict)
    target_account_id = json['targetAccountId']

    headers['Content-Type'] = 'application/json'

    begin
      FollowDeleter.call \
        account_id: account_id,
        target_account_id: target_account_id

      finish(nil, 410)
    rescue => e
      finish_json(errors: [e.to_s], status: 500)
    end
  end
end
