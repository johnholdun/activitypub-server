class InboxRoute < Route
  include JsonLdHelper

  def call
    request.body.rewind

    # All we're doing here is capturing this request to be parsed later by
    # {ParseInboxItem}
    DB[:unverified_inbox].insert \
      body: request.body.read.force_encoding('UTF-8'),
      headers: request['headers'].to_json,
      path: request.path,
      request_method: request.request_method.downcase,
      username: request.params['username']

    202
  end
end
