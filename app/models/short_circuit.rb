class ShortCircuit
  class NoActionSpecifiedError < StandardError; end

  def self.on(*args)
    self.new(*args)
  end

  def initialize(signal_name, &sc_blk)
    if sc_blk.nil?
      raise ::ShortCircuit::NoActionSpecifiedError.new("You must specify a short circuit action.")
    end
    @short_circuit_action = sc_blk
    @procs = []
  end

  def and_then(&blk)
    @procs << blk
    self
  end

  def call(value)
    failure_caught = catch(:fail) do
      result = @procs.inject(value) do |res, p|
        p.call(res)
      end
      return result
    end
    @short_circuit_action.call(failure_caught)
  end
end
