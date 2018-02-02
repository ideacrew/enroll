module TransportProfiles
  # Represents the context of a process, and the getting and setting of values
  # during it's execution.
  class ProcessContext
    attr_reader :process

    def initialize(transport_process)
      @process = transport_process
      @context_values = Hash.new
    end

    def put(key, value)
      raise NameError.new("name already exists in this context", key) if @context_values.has_key?(key.to_sym)
      @context_values[key.to_sym] = value
    end

    def get(key)
      @context_values.fetch(key.to_sym)
    end
  end
end
