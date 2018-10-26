class CreateStatusRoute < Route
  def call
    # TODO: authentication
    account_id = "#{BASE_URL}/users/john"

    request.body.rewind
    body = request.body.read.force_encoding('UTF-8')
    json = Oj.load(body, mode: :strict)
    text = json['text']
    in_reply_to = json['inReplyTo']
    sensitive = json['sensitive']
    summary = json['summary']

    headers['Content-Type'] = 'application/json'

    begin
      StatusCreator.call \
        account_id: account_id,
        text: text,
        in_reply_to: in_reply_to,
        sensitive: sensitive,
        summary: summary

      finish_json \
        data: {
          type: 'statuses',
          accountId: account_id,
          text: text,
          inReplyTo: in_reply_to,
          sensitive: sensitive,
          summary: summary,
        }
    rescue => e
      finish_json(errors: [e.to_s], status: 500)
    end
  end
end
