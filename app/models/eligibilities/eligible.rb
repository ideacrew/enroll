# frozen_string_literal: true

module Eligibilities
  # Use Visitor Development Pattern to access Eligibilities and Eveidences
  # distributed across models
  module Eligible
    def accept(eligibility)
      eligibility.visit(self)
    end
  end
end
