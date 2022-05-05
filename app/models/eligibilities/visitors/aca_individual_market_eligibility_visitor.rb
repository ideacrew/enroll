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

        outstanding_statuses = %w[outstanding review rejected]

        if outstanding_statuses.include?(verification_type.validation_status)
          evidence_state_attributes[:is_satisfied] = false
          evidence_state_attributes[:verification_outstanding] = true
          evidence_state_attributes[:due_on] = verification_type.due_date
        elsif verification_type.type_verified? || status_for(verification_type) == 'pending'
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
        return verification_type.validation_status if ['review', 'pending'].include?(verification_type.validation_status)

        verification_type.type_verified? ? 'determined' : 'outstanding'
      end
    end
  end
end
