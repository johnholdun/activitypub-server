class InboxRoute < Route
  include JsonLdHelper

  def call
    request.body.rewind

    # All we're doing here is capturing this request to be parsed later by
    # {ParseInboxItem}
    File.write \
      "inbox/#{(Time.now.to_f * 1000).to_i}.#{(rand * 8999 + 1000).to_i}.json",
      {
        body: request.body.read.force_encoding('UTF-8'),
        headers: request['headers'],
        path: request.path,
        request_method: request.request_method.downcase,
        username: request.params['username']
      }.to_json

    202
  end
end
