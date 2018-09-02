class FetchStatus
  include JsonLdHelper

  # FRESH_WINDOW = 60 * 60 * 24 * 3

  SUPPORTED_TYPES = %w(Note)

  def initialize(id)
    @id = id
  end

  def call
    status = fetch_saved
    return status if id.start_with?(BASE_URL)
    # fetched_at = STORAGE.read(:statusFetches, id).to_i
    return status if status # && Time.now.to_i - fetched_at <= FRESH_WINDOW
    status = fetch_by_id
    return unless status
    save_status(status)
    status
  end

  def self.call(*args)
    new(*args).call
  end

  private

  attr_reader :id

  def fetch_saved
    result = STORAGE.read(:statuses, id)
    LD_CONTEXT.merge(result) if result
  end

  def save_status(status)
    STORAGE.write(:statuses, id, status)
    # STORAGE.write(:statusFetches, id, Time.now.to_i)
  end

  def fetch_by_id
    json = fetch_resource(id, false)

    return unless supported_context?(json)

    supported_type =
      SUPPORTED_TYPES.any? { |type| equals_or_includes?(json['type'], type) }

    return unless supported_type

    json
  end

  def fetch_resource(uri, id)
    unless id
      json = fetch_resource_without_id_validation(uri)
      return unless json
      return json if uri == json['id']
      uri = json['id']
    end

    json = fetch_resource_without_id_validation(uri)
    return unless json && json['id'] == uri
    json
  end

  def fetch_resource_without_id_validation(uri)
    Request
      .new(
        :get,
        uri,
        headers: { 'Accept' => 'application/activity+json, application/ld+json' }
      )
      .perform do |response|
        return Oj.load(response, mode: :strict) if response.code == 200
      end
  rescue Oj::ParseError
    nil
  end

  def supported?(json)
    return unless supported_context?(json)
    SUPPORTED_TYPES.any? { |type| equals_or_includes?(json['type'], type) }
  end
end
