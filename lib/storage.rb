class Storage
  def initialize(path)
    @path = path
    load!
  end

  def load!
    @data = Oj.load(File.read(@path))
    @last_write = Time.now.to_i
  end

  def persist!
    # TODO: Lock file
    File.write(@path, Oj.dump(@data, mode: :compat))
    @last_write = Time.now.to_i
  end

  def list(type, options = {})
    raise ArgumentError, 'unexpected type' unless @data[type.to_s].is_a?(Hash)
    return @data[type.to_s].values
  end

  def read(type, id = nil)
    if id
      @data.dig(type.to_s, id.to_s)
    else
      @data[type.to_s]
    end
  end

  def write(type, id, value)
    raise ArgumentError, 'unexpected type' unless @data[type.to_s].is_a?(Hash)
    @data[type.to_s][id.to_s] = value
    persist! if ready_to_persist?
  end

  def append(type, id, item)
    raise ArgumentError, 'unexpected type' unless @data[type.to_s].is_a?(Hash)
    @data[type.to_s][id.to_s] ||= []
    unless @data[type.to_s][id.to_s].is_a?(Array)
      raise ArgumentError, 'unexpected item'
    end
    @data[type.to_s][id.to_s].push(item)
    persist! if ready_to_persist?
  end

  def remove(type, id, item)
    raise ArgumentError, 'unexpected type' unless @data[type.to_s].is_a?(Hash)
    @data[type.to_s][id.to_s] ||= []
    unless @data[type.to_s][id.to_s].is_a?(Array)
      raise ArgumentError, 'unexpected item'
    end
    @data[type.to_s][id.to_s].reject! { |i| i == item }
    persist! if ready_to_persist?
  end

  private

  def ready_to_persist?
    true
    # TODO: What if we get a bunch of writes within this window and then the
    # window passes? Do we schedule a persist for later? How? Should this all
    # just be Redis?
    # Time.now - @last_write > 10
  end
end
