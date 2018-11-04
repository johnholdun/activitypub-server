class FetchStatus
  include JsonLdHelper

  def initialize(id)
    @id = id
  end

  def call
    status = fetch_saved
    return status if id.start_with?(BASE_URL)
    return status if status
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
    result = DB[:objects].where(id: id).first
    LD_CONTEXT.merge(Oj.load(result[:json])) if result
  end

  def save_status(object)
    DB[:objects].insert \
      id: object['id'],
      type: object['type'],
      published: object['published'],
      json: object.to_json
  end

  def fetch_by_id
    json = fetch_resource(id, false)

    return unless supported_context?(json)

    supported_type =
      ActivityPub::OBJECT_TYPES.any? do |type|
        equals_or_includes?(json['type'], type)
      end

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
    ActivityPub::OBJECT_TYPES.any? do |type|
      equals_or_includes?(json['type'], type)
    end
  end
end
