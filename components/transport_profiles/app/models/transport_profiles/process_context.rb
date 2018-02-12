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

    # Transform a given value in the process context.
    # @param key [String, Symbol] the key of the managed value
    # @param initial_value [Object] the value to use if the key has not yet been set
    # @yieldparam context_value [Object] the current key value, or initial_value if unset
    # @yieldreturn [Object] the new value to place in the context
    def update(key, initial_value = nil)
      if @context_values.has_key?(key.to_sym)
        @context_values[key.to_sym] = yield @context_values[key.to_sym]
      else
        @context_values[key.to_sym] = yield initial_value
      end
    end
  end
end
