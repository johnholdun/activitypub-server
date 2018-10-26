class ReadItemsRoute < Route
  def call
    # TODO: authentication
    # TODO: filtering and pagination
    items = STORAGE.list(:incomingItems)
    headers['Content-Type'] = 'application/json'
    finish_json(data: items)
  end
end
