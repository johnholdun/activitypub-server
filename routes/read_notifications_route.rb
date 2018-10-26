class ReadNotificationsRoute < Route
  def call
    # TODO: authentication
    # TODO: filtering and pagination
    items = STORAGE.read(:notifications, "#{BASE_URL}/users/john")
    headers['Content-Type'] = 'application/json'
    finish_json(data: items)
  end
end
