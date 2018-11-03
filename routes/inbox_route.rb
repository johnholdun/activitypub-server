class InboxRoute < Route
  include JsonLdHelper

  def call
    request.body.rewind

    # All we're doing here is capturing this request to be parsed later by
    # {ParseInboxItem}
    STORAGE.write \
      :unverifiedInbox,
      "#{(Time.now.to_f * 1000).to_i}.#{(rand * 8999 + 1000).to_i}",
      {
        body: request.body.read.force_encoding('UTF-8'),
        headers: request['headers'],
        path: request.path,
        request_method: request.request_method.downcase,
        username: request.params['username']
      }

    202
  end
end
