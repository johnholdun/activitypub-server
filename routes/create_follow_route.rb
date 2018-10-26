class CreateFollowRoute < Route
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
      FollowCreator.call \
        account_id: account_id,
        target_account_id: target_account_id

      finish_json \
        data: {
          type: 'follows',
          accountId: account_id,
          targetAccountId: target_account_id
        }
    rescue => e
      finish_json(errors: [e.to_s], status: 500)
    end
  end
end
