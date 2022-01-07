# frozen_string_literal: true

module Eligibilities
  module Visitors
    # Individual market eligibility visitor
    class AcaIndividualMarketEligibilityVisitor < Visitor
      attr_accessor :evidence, :subject, :evidence_item, :effective_date

      def call
        person = subject.person
        person.accept(self)
      end

      def visit(verification_type)
        return unless verification_type.type_name.downcase == evidence_item.key.titleize.downcase

        evidence_state_attributes = {
          status: status_for(verification_type),
          visited_at: DateTime.now,
          evidence_gid: verification_type.to_global_id.uri
        }

        outstanding_statuses = %w[unverified outstanding pending review]

        if outstanding_statuses.include?(verification_type.validation_status)
          evidence_state_attributes[:is_satisfied] = false
          evidence_state_attributes[:verification_outstanding] = true
          evidence_state_attributes[:due_on] = verification_type.due_date
        elsif verification_type.type_verified?
          evidence_state_attributes[:is_satisfied] = true
          evidence_state_attributes[:verification_outstanding] = false
          evidence_state_attributes[:due_on] = nil
        end

        @evidence =
          Hash[
            evidence_item[:key].to_sym,
            evidence_state_attributes.symbolize_keys
          ]
      end

      private

      def status_for(verification_type)
        return 'review' if verification_type.validation_status == 'review'

        verification_type.type_verified? ? 'determined' : 'outstanding'
      end
    end
  end
end
