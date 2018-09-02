class Route
  def initialize(request)
    @request = request
    @headers = {}
  end

  def call
    raise NotImplementedError
  end

  def self.call(*args)
    new(*args).call
  end

  private

  attr_reader :request, :headers

  def not_found(body = nil)
    finish(body, 404)
  end

  def finish(body = nil, status = 200)
    [status, headers, [body].compact]
  end

  def finish_json(json, status = 200)
    finish(Oj.dump(json, mode: :compat), status)
  end
end
