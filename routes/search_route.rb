class SearchRoute < Route
  def call
    uri = request.params['id'].to_s.strip

    return finish_json(data: nil) if uri.size.zero?

    account = FetchAccount.call(uri)

    return not_found unless account

    headers['Content-Type'] = 'application/json'

    finish_json(data: account)
  end
end
