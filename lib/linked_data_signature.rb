class Symbol
  def start_with?(*args)
    to_s.start_with?(*args)
  end
end

class LinkedDataSignature
  include JsonLdHelper

  CONTEXT = 'https://w3id.org/identity/v1'

  def initialize(json)
    @json = json
  end

  def verify_account!
    return unless @json['signature'].is_a?(Hash)

    type = @json['signature']['type']
    creator_uri = @json['signature']['creator']
    signature = @json['signature']['signatureValue']

    return unless type == 'RsaSignature2017'

    creator = FetchAccount.call(creator_uri)

    return if creator.nil?

    options_hash =
      hash \
        @json['signature']
          .reject { |k, _| %w(type id signatureValue).include?(k) }
          .merge('@context' => CONTEXT)

    document_hash = hash(@json.reject { |k, _| k == 'signature' })

    to_be_verified = options_hash + document_hash

    keypair =
      OpenSSL::PKey::RSA.new(creator['publicKey']['publicKeyPem'])

    verified =
      keypair
      .public_key
      .verify \
        OpenSSL::Digest::SHA256.new,
        Base64.decode64(signature),
        to_be_verified

    return creator if verified
  end

  def sign!(creator)
    options = {
      'type' => 'RsaSignature2017',
      'creator' => "#{creator['id']}#main-key",
      'created' => Time.now.utc.iso8601,
    }

    options_hash =
      hash \
        options
          .reject { |k, _| %w(type id signatureValue).include?(k) }
          .merge('@context' => CONTEXT)

    document_hash = hash(@json.reject { |k, _| k == 'signature' })

    to_be_signed = options_hash + document_hash

    keypair =
      OpenSSL::PKey::RSA.new(STORAGE.read(:privateKeys, creator['id']))

    signature =
      Base64.strict_encode64 \
        keypair.sign(OpenSSL::Digest::SHA256.new, to_be_signed)

    @json.merge('signature' => options.merge('signatureValue' => signature))
  end

  private

  def hash(json)
    graph = RDF::Graph.new
    graph << JSON::LD::API.toRdf(json, documentLoader: method(:load_jsonld_context))
    Digest::SHA256.hexdigest(graph.dump(:normalize))
  end

  # TODO: cache this for a long time (30 days)
  def load_jsonld_context(url, _options = {}, &_block)
    json =
      Request
        .new(:get, url, headers: { 'Accept' => 'application/ld+json' })
        .perform do |res|
          unless res.code == 200 && res.mime_type == 'application/ld+json'
            raise JSON::LD::JsonLdError::LoadingDocumentFailed
          end
          res.body_with_limit
        end

    doc = JSON::LD::API::RemoteDocument.new(url, json)

    block_given? ? yield(doc) : doc
  end
end
