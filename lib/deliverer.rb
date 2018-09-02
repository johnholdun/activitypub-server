class Deliverer
  def initialize(account, inbox_urls, body)
    @account = account
    @inbox_urls = inbox_urls
    @body = body
  end

  def call
    inbox_urls.each do |inbox_url|
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
        end
    end
  end

  def self.call(*args)
    new(*args).call
  end

  private

  attr_reader :account, :inbox_urls, :body

  def json
    @json ||=
      Oj.dump \
        LinkedDataSignature.new(LD_CONTEXT.merge(body)).sign!(account)
  end
end
