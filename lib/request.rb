class Request
  REQUEST_TARGET = '(request-target)'

  def initialize(verb, url, **options)
    raise ArgumentError unless url

    @verb = verb
    @url = Addressable::URI.parse(url).normalize
    @options = (options || {}).reject { |k, _| %i(account headers).include?(k) }
    @headers = options[:headers] || {}

    set_common_headers!
    set_digest! if options.key?(:body)
    account = options[:account]

    if account
      keypair =
        OpenSSL::PKey::RSA.new(STORAGE.read(:privateKeys, account['id']))

      signature =
        Base64.strict_encode64 \
          keypair.sign(OpenSSL::Digest::SHA256.new, signed_string)

      signed_headers = @headers.keys.join(' ').downcase

      signature =
        "keyId=\"#{account['publicKey']['id']}\"," +
        'algorithm="rsa-sha256",' +
        "headers=\"#{signed_headers}\"," +
        "signature=\"#{signature}\""

      @headers['Signature'] = signature
    end
  end

  def perform
    begin
      response =
        http_client
          .headers(@headers.reject { |k, _| k == REQUEST_TARGET })
          .public_send(@verb, @url.to_s, @options)
    rescue => e
      raise e.class, "#{e.message} on #{@url}", e.backtrace[0]
    end

    begin
      yield response.extend(ClientLimit)
    ensure
      http_client.close
    end
  end

  private

  def set_common_headers!
    @headers[REQUEST_TARGET] = "#{@verb} #{@url.path}"
    @headers['User-Agent'] = "#{HTTP::Request::USER_AGENT} (HoldunPub/0.0.1; +#{BASE_URL}/)"
    @headers['Host'] = @url.host
    @headers['Date'] = Time.now.utc.httpdate
    @headers['Accept-Encoding'] = 'gzip' if @verb != :head
  end

  def set_digest!
    @headers['Digest'] =
      "SHA-256=#{Digest::SHA256.base64digest(@options[:body])}"
  end

  def signed_string
    @headers.map { |key, value| "#{key.downcase}: #{value}" }.join("\n")
  end

  def timeout
    { write: 10, connect: 10, read: 10 }
  end

  def http_client
    @http_client ||=
      HTTP
        .use(:auto_inflate)
        .timeout(:per_operation, timeout)
        .follow(max_hops: 2)
  end

  module ClientLimit
    def body_with_limit(limit = 1_048_576)
      if content_length.to_s.size > limit
        raise 'content too long'
      end

      if charset.nil?
        encoding = Encoding::BINARY
      else
        begin
          encoding = Encoding.find(charset)
        rescue ArgumentError
          encoding = Encoding::BINARY
        end
      end

      contents = String.new(encoding: encoding)

      while (chunk = readpartial)
        contents << chunk
        chunk.clear

        raise 'too big' if contents.bytesize > limit
      end

      contents
    end
  end

  private_constant :ClientLimit
end
