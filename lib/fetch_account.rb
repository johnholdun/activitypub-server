require './lib/jsonld_helper'

class FetchAccount
  include JsonLdHelper

  FRESH_WINDOW = 60 * 60 * 24 * 3
  DFRN_NS = 'http://purl.org/macgirvin/dfrn/1.0'

  def initialize(id)
    @id = id
  end

  def call
    account = fetch_saved
    return account if id.start_with?(BASE_URL)
    return account if account && Time.now.to_i - account[:fetched_at].to_i <= FRESH_WINDOW
    account = fetch_webfinger || fetch_by_id
    return unless account
    save_account(account)
    account
  end

  def self.call(*args)
    new(*args).call
  end

  private

  attr_reader :id

  def fetch_saved
    result = DB[:actors].where(id: id).first
    LD_CONTEXT.merge(Oj.load(result[:json])) if result
  end

  def save_account(account)
    existing = DB[:actors].where(id: id)

    params =
      {
        fetched_at: Time.now,
        json: account.reject { |k, _| k == '@context' }.to_json
      }

    if existing.count > 0
      existing.update(params)
    else
      DB[:actors].insert(params.merge(id: id))
    end
  end

  def fetch_by_id
    json = fetch_resource(id, false)

    return unless supported_context?(json)

    supported_type =
      ActivityPub::ACTOR_TYPES.any? do |type|
        equals_or_includes?(json['type'], type)
      end

    return unless supported_type

    return unless verified_account?(json)

    json
  end

  def fetch_webfinger(redirect_uri = nil)
    return unless (redirect_uri || id).start_with?('acct:')

    puts "Looking up webfinger for #{redirect_uri || id}"

    webfinger_client =
      Goldfinger::Client.new \
        redirect_uri || id,
        ssl: true,
        headers: {
          'User-Agent' => "#{HTTP::Request::USER_AGENT} (HoldunPub/0.0.1; +#{BASE_URL}/)"
        }

    webfinger = webfinger_client.finger

    if webfinger.subject == id
      # ok
    elsif !redirect_uri
      return fetch_webfinger(webfinger.subject)
    else
      puts 'Requested and returned acct URIs do not match'
      return
    end

    return if webfinger.link('self').nil?

    return unless [
      'application/activity+json',
      'application/ld+json; profile="https://www.w3.org/ns/activitystreams"'
    ].include?(webfinger.link('self').type)

    json = fetch_resource(webfinger.link('self').href, false)
    return unless supported?(json) && json['inbox']

    json
  rescue Goldfinger::Error => e
    puts "Webfinger query for #{id} unsuccessful: #{e}"
    nil
  rescue Oj::ParseError
    nil
  end

  def verified_account?(json)
    verified_webfinger? \
      json['id'],
      json['preferredUsername'],
      Addressable::URI.parse(id).normalized_host
  end

  def verified_webfinger?(uri, username, domain)
    acct = "acct:#{username}@#{domain}"

    webfinger_client =
      Goldfinger::Client.new \
        acct,
        ssl: true,
        headers: {
          'User-Agent' => "#{HTTP::Request::USER_AGENT} (HoldunPub/0.0.1; +#{BASE_URL}/)"
        }

    webfinger = webfinger_client.finger

    if acct.casecmp(webfinger.subject).zero?
      return webfinger.link('self')&.href == id
    end

    return verified_webfinger?(uri, confirmed_username, confirmed_domain)
  rescue Goldfinger::Error
    false
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
    ActivityPub::ACTOR_TYPES.any? do |type|
      equals_or_includes?(json['type'], type)
    end
  end
end
