class ParseInboxItem
  include JsonLdHelper

  def call
    filename = Dir.glob('inbox/*.json').first
    raise 'no items' unless filename
    @timestamp = File.basename(filename).split('.').first.to_i
    @payload = Oj.load(File.read(filename), mode: :strict)

    inbox_account =
      FetchAccount.call("#{BASE_URL}/users/#{payload['username']}")

    raise 'user not found' unless inbox_account

    process \
      inbox_account,
      payload['body'],
      signed_request_account
  rescue => error
    return unless filename

    File.write \
      "inbox-errors/#{File.basename(filename)}",
      payload.merge(error: error).to_json
  ensure
    FileUtils.rm(filename) if filename
  end

  def self.call
    new.call
  end

  private

  attr_reader :payload, :timestamp

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
      HandleIncomingItem.call(inbox_account, item, timestamp)
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
    raise 'Request not signed' unless payload['headers']['Signature'].to_s.size > 0

    # begin
    #   time_sent = DateTime.httpdate(payload['headers']['Date'])
    # rescue ArgumentError
    #   raise 'Invalid date'
    # end

    # unless (Time.now.utc - time_sent).abs <= 30
    #   raise 'Expired date'
    # end

    signature_params = {}

    payload['headers']['Signature'].split(',').each do |part|
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
          "#{Request::REQUEST_TARGET}: #{payload['request_method']} #{payload['path']}"
        elsif signed_header == 'digest'
          "digest: SHA-256=#{Digest::SHA256.base64digest(payload['body'])}"
        else
          header =
            payload['headers'][signed_header.split(/-/).map(&:capitalize).join('-')]

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
