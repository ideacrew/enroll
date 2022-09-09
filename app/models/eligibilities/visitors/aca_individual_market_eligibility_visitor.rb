# frozen_string_literal: true

module Eligibilities
  module Visitors
    # Individual market eligibility visitor
    class AcaIndividualMarketEligibilityVisitor < Visitor
      attr_accessor :evidence, :subject, :evidence_item, :effective_date

      OUTSTANDING_STATES = %w[outstanding review rejected].freeze
      PENDING_STATES = %w[pending unverified negative_response_received].freeze

      def call
        person = subject.person
        person.accept(self)
      end

      def visit(verification_type)
        evidence_key = evidence_item.key.downcase == "residency" ? "#{site_key}_residency" : evidence_item.key
        return unless verification_type.type_name.downcase == evidence_key.titleize.downcase

        status_for = status_for(verification_type)
        evidence_state_attributes = {
          status: status_for,
          visited_at: DateTime.now,
          evidence_gid: verification_type.to_global_id.uri
        }

        if OUTSTANDING_STATES.include?(verification_type.validation_status)
          evidence_state_attributes[:is_satisfied] = false
          evidence_state_attributes[:verification_outstanding] = true
          evidence_state_attributes[:due_on] = verification_type.due_date
        elsif verification_type.type_verified? || PENDING_STATES.include?(status_for)
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
        return verification_type.validation_status if PENDING_STATES.include?(verification_type.validation_status)

        verification_type.type_verified? ? 'determined' : 'outstanding'
      end
    end
  end
end
