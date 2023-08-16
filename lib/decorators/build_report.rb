# frozen_string_literal: true

module Decorators
  # Generic decorator to build report
  class BuildReport
    def initialize(decorator, logger)
      @decorator = decorator
      @logger = logger
    end

    def append_data(data)
      @decorator.append_data(data)
    end
  end
end
