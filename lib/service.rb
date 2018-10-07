class Service
  def initialize(**args)
    @args = args || {}
  end

  def call
    raise NotImplementedError
  end

  def self.call(**args)
    new(**args).call
  end

  def self.attribute(name)
    (@attributes ||= []).push(name)
    define_method(name) { @args[name] }
  end
end
