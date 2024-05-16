# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

#   - key: :non_esi_evidence
#     is_enabled: true
#     settings:
#       - key: :subject_ref
#         item: 'gid://enroll_app/Family::FamilyMember'
#       - key: :evidence_ref
#         item: 'gid://enroll_app/FinancialAssitance::Application'

module Operations
  module Eligibilities
    # Build Evidence state for the evidence item passed
    class BuildEvidenceState
      include Dry::Monads[:do, :result]

      # @param [Hash] opts Options to build evidence
      # @option opts [GlobalID] :subject required
      # @option opts [AcaEntities::Elgibilities::EligibilityItem] :eligibility_item required
      # @option opts [AcaEntities::Elgibilities::EvidenceItem] :evidence_item required
      # @option opts [Date] :effective_date required
      # @return [Dry::Monad] result
      def call(params)
        values = yield validate(params)
        subject = yield find_subject(values)
        evidence_state = yield build_evidence_state(subject, values)

        Success(evidence_state)
      end

      private

      def validate(params)
        errors = []
        errors << 'subject missing' unless params[:subject]
        errors << 'eligibility item missing' unless params[:eligibility_item]
        errors << 'evidence item missing' unless params[:evidence_item]
        errors << 'effective date missing' unless params[:effective_date]

        errors.empty? ? Success(params) : Failure(errors)
      end

      def find_subject(values)
        subject = GlobalID::Locator.locate values[:subject]

        Success(subject)
      end

      def build_evidence_state(subject, values)
        visitor = visitor_klass(values[:eligibility_item]).new
        visitor.subject = subject
        visitor.evidence_item = values[:evidence_item]
        visitor.effective_date = values[:effective_date]
        visitor.call

        evidence = visitor.evidence
        evidence ||= Hash[values[:evidence_item][:key], {}]

        Success(evidence)
      end

      def visitor_klass(eligibility_item)
        "Eligibilities::Visitors::#{eligibility_item.key.classify}Visitor"
          .constantize
      end
    end
  end
end
