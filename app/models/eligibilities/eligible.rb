# frozen_string_literal: true

module Eligibilities
  # Use Visitor Development Pattern to access Eligibilities and Eveidences
  # distributed across models
  module Eligible
    def accept(visitor)
      visitor.visit(self)
    end
  end
end
