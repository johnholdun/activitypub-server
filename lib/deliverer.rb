class Deliverer
  def initialize(account, inbox_url, body)
    @account = account
    @inbox_url = inbox_url
    @body = body
  end

  def call
    response =
      Request
        .new(
          :post,
          inbox_url,
          body: json,
          headers: { 'Content-Type' => 'application/activity+json' },
          account: account
        )
        .perform do |response|
          puts "Response from #{inbox_url}:\n#{response.inspect}"
          puts "~ #{response.body}" unless response.body.to_s.strip.size.zero?
          response.status.code
        end

    { inbox_url: inbox_url, response: response }
  end

  def self.call(*args)
    new(*args).call
  end

  private

  attr_reader :account, :inbox_url, :body

  def json
    @json ||=
      Oj.dump \
        LinkedDataSignature.new(LD_CONTEXT.merge(body)).sign!(account)
  end
end
