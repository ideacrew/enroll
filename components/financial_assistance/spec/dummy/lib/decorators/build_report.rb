# frozen_string_literal: true

module Decorators
  # Generic decorator to build report
  class BuildReport
    def initialize(decorator)
      @decorator = decorator
    end

    def append_data(data)
      @decorator.append_data(data)
    end
  end
end
