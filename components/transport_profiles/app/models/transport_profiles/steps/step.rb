module TransportProfiles
  class Steps::Step
    attr_reader :description

    def initialize(description, gateway)
      @description = description
      @gateway = gateway
    end

    def execute
    end

  end
end
