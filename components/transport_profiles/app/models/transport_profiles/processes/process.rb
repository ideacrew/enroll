module TransportProfiles
  class Processes::Process

    attr_reader :descriptions, :gateway, :steps

    def initialize(description, gateway)
      @description = description
      @steps = []
      @gateway = gateway
    end

    def add_step(new_step)
      @steps << new_step
    end

    def step_descriptions
      @steps.map { |step| step.description + '\n'  }
    end

    def execute(context = nil)
      context ||= TransportProfiles::ProcessContext.new(self)
      @steps.each do |step|
        begin
          # TODO add logging at start and end of step execution
          step.execute(context)
        rescue => e
          Rails.logger.error { e }
          Rails.logger.error { e.backtrace.join("\n") }
          # TODO add error logging
          # TODO determine if steps should continue when an error is raised
        end
      end
    end

    def self.used_endpoints
      raise NotImplementedError.new("subclass responsibility")
    end

    def self.used_context_names
      []
    end
  end
end
