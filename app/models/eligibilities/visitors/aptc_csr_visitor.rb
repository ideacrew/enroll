# frozen_string_literal: true

module Eligibilities::Visitors
  # Use Visitor Development Pattern to access models and determine Non-ESI
  # eligibility status for a Family Financial Assistance Application's Applicants
  class AptcCsrVisitor < Visitor
    attr_accessor :evidences, :family_member, :evidence_items

    # EVIDENCES = %i[income_evidence esi_evidence non_esi_evidence aces_evidence]

    # def self.get_evidence_on(evidence_key, date)
    #   @evidence_key = evidence_key
    #   @evidence_date = date
    #   application =
    #     Klass.where(family_id: enrollment.family_id, aasm_state: :determined)
    #       .last
    #   application.accept(self.new)
    # end

    def visit(applicant)
      @evidences =
        evidence_items
          .collect do |evidence_item|
            evidence = applicant.send(evidence_item[:key])
            ids = {
              'subject_gid' => family_member.to_global_id.uri,
              'evidence_gid' => evidence.to_global_id.uri,
              'visited_at' => DateTime.now,
              'state' => evidence.aasm_state
            }
            Hash[
              evidence_item[:key],
              evidence
                .attributes
                .slice('is_satisfied', 'verification_outstanding', 'due_on')
                .merge(ids)
            ]
          end
          .reduce(:merge)

      evidences
    end
  end
end

# module FinancialAssistance
# class Application

#   include Visitable

#   def accept(visitor)
#     applicants.each do |applicant|
#       applicant.accept(visitor)
#     end

#     tax_household.accept(visitor)
#   end
# end

# class Applicant
#     include Visitable
#     def accept(visitor)
#       visitor.visit(self)
#     end
#   end
# end

# class TaxHousehold
#     include Visitable
#     def accept(visitor)
#       visitor.visit(self)
#     end
#   end
# end

# application = FinancialAssistance::Application.new

# application.accept(Eligibilities::Visitors::FaaApplicationVisitor.new)

# module Eligibilities::Visitors
#   # Use Visitor Development Pattern to access models and determine Non-ESI
#   # eligibility status for a Family Financial Assistance Application's Applicants
#   class FaaApplicationVisitor < Visitor

#     # def visit_evidences(evidences)
#     #   self
#     #     .applicants
#     #     .reduce([]) do |memo, applicant|
#     #       applicant_evidences([]) do |evidence|
#     #         # << send(:applicant)
#     #       end
#     #     end

#     def visit(subject)

#       if subject.class == Applicant
#         @applicant_values ||= []
#         @applicant_values << subject.attributes.slice(:attribute_1)
#       elsif subject.class == TaxHousehod

#       end

#       puts "Evidence: #{subject.resource}, Satisfied? #{subject.is_satisfied}"
#     end
#     # end
#   end
# end
