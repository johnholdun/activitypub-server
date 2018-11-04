class ParseInbox
  include JsonLdHelper

  def call
    puts 'Checking queue…'

    @payload = DB[:unverified_inbox].where(errors: nil).first
    raise 'no items' unless payload

    inbox_account =
      FetchAccount.call("#{BASE_URL}/users/#{payload[:username]}")

    raise 'user not found' unless inbox_account

    process \
      inbox_account,
      payload[:body],
      signed_request_account

    DB[:unverified_inbox]
      .where(id: payload[:id])
      .delete
  rescue => error
    unless payload
      puts 'no items in queue'
      return
    end

    DB[:unverified_inbox]
      .where(id: payload[:id])
      .update(errors: error.to_json)
  ensure
    # Unless we hit the end of the queue, run this again
    self.call if payload
  end

  def self.call
    new.call
  end

  private

  attr_reader :payload

  def headers
    @headers ||= Oj.load(payload[:headers]) rescue {}
  end

  def process(inbox_account, body, account)
    json = Oj.load(body, mode: :strict)

    return unless supported_context?(json)

    if different_actor?(json, account)
      account =
        begin
          LinkedDataSignature.new(json).verify_account!
        rescue JSON::LD::JsonLdError => e
          puts \
            "Could not verify LD-Signature for #{value_or_id(json['actor'])}: #{e.message}"
          nil
        end

      return unless account
    end

    object = json['object']
    if object.is_a?(String)
      # TODO: Fetch object at this URI for local storage
    else
      # TODO: Verify that this object is real
      # TODO: Be careful about intended audience for this object?
      existing = DB[:objects].where(id: object['id'])

      if existing.count > 0
        existing.update(json: object.to_json)
      else
        DB[:objects].insert \
          id: object['id'],
          type: object['type'],
          published: object['published'],
          json: object.to_json
      end

      json['object'] = object['id']
    end

    params =
      {
        id: json['id'],
        type: json['type'],
        actor: json['actor'],
        object: json['object'],
        target: json['target'],
        published: json['published'],
        json: json.reject { |k, _| %w(@context signature).include?(k) }.to_json
      }

    existing = DB[:activities].where(id: params[:id])

    if existing.count > 0
      existing.update(params)
    else
      DB[:activities].insert(params)
    end

    inbox_params =
      {
        actor: inbox_account['id'],
        activity: json['id']
      }

    DB[:inbox].where(inbox_params).delete
    DB[:inbox].insert(inbox_params)

    items =
      case json['type']
      when 'Collection', 'CollectionPage'
        json['items']
      when 'OrderedCollection', 'OrderedCollectionPage'
        json['orderedItems']
      else
        [json]
      end

    items.reverse_each do |item|
      HandleIncomingItem.call(inbox_account, item, object)
    end
  rescue Oj::ParseError
    nil
  end

  def different_actor?(json, account)
    !json['actor'].to_s.size.zero? &&
    value_or_id(json['actor']) != account['id'] &&
    !json['signature'].to_s.size.zero?
  end

  def signed_request_account
    raise 'Request not signed' unless headers['Signature'].to_s.size > 0

    # begin
    #   time_sent = DateTime.httpdate(headers['Date'])
    # rescue ArgumentError
    #   raise 'Invalid date'
    # end

    # unless (Time.now.utc - time_sent).abs <= 30
    #   raise 'Expired date'
    # end

    signature_params = {}

    headers['Signature'].split(',').each do |part|
      parsed_parts = part.match(/([a-z]+)="([^"]+)"/i)
      next if parsed_parts.nil? || parsed_parts.size != 3
      signature_params[parsed_parts[1]] = parsed_parts[2]
    end

    unless signature_params['keyId'] && signature_params['signature']
      raise 'Incompatible request signature'
    end

    account = FetchAccount.call(signature_params['keyId'].sub(/#.+/, ''))

    unless account
      raise "Public key not found for key #{signature_params['keyId']}"
    end

    signed_headers = signature_params['headers'] || 'date'

    signed_string =
      signed_headers
      .split(' ')
      .map do |signed_header|
        if signed_header == Request::REQUEST_TARGET
          "#{Request::REQUEST_TARGET}: #{payload[:request_method]} #{payload[:path]}"
        elsif signed_header == 'digest'
          "digest: SHA-256=#{Digest::SHA256.base64digest(payload[:body])}"
        else
          header =
            headers[signed_header.split(/-/).map(&:capitalize).join('-')]

          "#{signed_header}: #{header}"
        end
      end
      .join("\n")

    keypair =
      OpenSSL::PKey::RSA.new(account['publicKey']['publicKeyPem'])

    verified =
      keypair
        .public_key
        .verify \
          OpenSSL::Digest::SHA256.new,
          Base64.decode64(signature_params['signature']),
          signed_string

    return account if verified

    raise "Verification failed for #{account['id']}"
  end
end
