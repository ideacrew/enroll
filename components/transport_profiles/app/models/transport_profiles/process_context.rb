module TransportProfiles
  # Represents the context of a process, and the getting and setting of values during its execution.
  class ProcessContext
    attr_reader :process

    def initialize(transport_process)
      @process = transport_process
      @context_values = Hash.new
    end

    # Place a value into the context for use later on in the process.
    # @raise [NameError] if the name is already in use
    def put(key, value)
      raise NameError.new("name already exists in this context", key) if @context_values.has_key?(key.to_sym)
      @context_values[key.to_sym] = value
    end

    # Retrieve a value from the context for use.
    # @raise [KeyError] if the value was never assigned
    def get(key)
      @context_values.fetch(key.to_sym)
    end
  end
end
