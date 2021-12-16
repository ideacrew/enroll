# frozen_string_literal: true

module Eligibilities
  module Visitors
  # Use Visitor Development Pattern to access models and determine Non-ESI
  # eligibility status for a Family Financial Assistance Application's Applicants
    class FaaApplicationVisitor < Visitor
      EVIDENCES = {
        applicants: %i[esi non_esi medicare],
        tax_household: [:income]
      }.freeze

      def visit_evidences(_evidences)
        self
          .applicants
          .reduce([]) do |_memo, _applicant|
            applicant_evidences([]) do |evidence|
              # << send(:applicant)
            end
          end
      end

      def visit(_applicant)
        puts "Evidence: #{subject.resource}, Satisfied? #{subject.is_satisfied}"
      end
    end
  end
end
