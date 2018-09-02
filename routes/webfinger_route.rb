class WebfingerRoute < Route
  def call
    resource = request.params['resource']

    username_from_resource =
      case resource
      when /\A#{BASE_URL}/i
        # TODO: find account by this URL as ID
      when /\@/
        username, domain = resource.gsub(/\Aacct:/, '').split('@', 2)
        if domain.gsub(/[\/]/, '').casecmp(LOCAL_DOMAIN).zero?
          username
        end
      end

    return not_found unless username_from_resource

    @account =
      FetchAccount.call("#{BASE_URL}/users/#{username_from_resource}")

    return not_found unless @account

    headers['Vary'] = 'Accept'
    headers['Content-Type'] = 'application/jrd+json'
    headers['Cache-Control'] = 'max-age=259200, public'

    finish_json \
      subject: uri,
      aliases: [@account['id']],
      links: [
        {
          rel: 'self',
          type: 'application/activity+json',
          href: @account['id']
        },
        {
          rel: 'magic-public-key',
          href: "data:application/magic-public-key,#{magic_key}"
        }
      ]
  end

  private

  def uri
    @uri ||= "acct:#{@account['preferredUsername']}@#{LOCAL_DOMAIN}"
  end

  def private_key
    STORAGE.read(:privateKeys, uri)
  end

  def public_key
    @account['publicKey']['publicKeyPem']
  end

  def magic_key
    keypair = OpenSSL::PKey::RSA.new(private_key || public_key)

    modulus, exponent =
      [keypair.public_key.n, keypair.public_key.e].map do |component|
        result = []

        until component.zero?
          result << [component % 256].pack('C')
          component >>= 8
        end

        result.reverse.join
      end

    "RSA.#{Base64.urlsafe_encode64 modulus}.#{Base64.urlsafe_encode64 exponent}"
  end
end
