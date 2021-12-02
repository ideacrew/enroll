# frozen_string_literal: true

module Eligibilities
  module Visitors
  # Use Visitor Development Pattern to access models and determine Non-ESI
  # eligibility status for a Family Financial Assistance Application's Applicants
    class NonEsiVisitor < Visitor
      def visit(subject)
        puts "Evidence: #{subject.resource}, Satisfied? #{subject.is_satisfied}"
      end
    end
  end
end
