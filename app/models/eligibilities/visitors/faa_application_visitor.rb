# frozen_string_literal: true

module Eligibilities::Visitors
  # Use Visitor Development Pattern to access models and determine Non-ESI
  # eligibility status for a Family Financial Assistance Application's Applicants
  class FaaApplicationVisitor < Visitor
    Klass = Faa::Application
    Evidences = {
      applicants: %i[esi non_esi medicare],
      tax_household: [:income]
    }

    def visit_evidences(evidences)
      self
        .applicants
        .reduce([]) do |memo, applicant|
          applicant_evidences([]) do |evidence|
            # << send(:applicant)
          end
        end

      def visit(applicant)
        puts "Evidence: #{subject.resource}, Satisfied? #{subject.is_satisfied}"
      end
    end
  end
end
