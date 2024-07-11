# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Eligibilities
    # Build Eligibility state for the eligibility item passed
    class BuildEligibilityState
      include Dry::Monads[:do, :result]

      # @param [Hash] opts Options to build eligibility state
      # @option opts [GlobalID] :subject required
      # @option opts [AcaEntities::Eligibilities::EligibilityItem] :eligibility_item required
      # @option opts [Array<Symbol>] :evidence_item_keys optional
      # @option opts [Date] :effective_date required
      # @return [Dry::Monad] result
      def call(params)
        values = yield validate(params)
        eligibility_state = yield build_eligibility_state(values)

        Success(eligibility_state)
      end

      private

      def validate(params)
        errors = []
        errors << 'subject missing' unless params[:subject]
        errors << 'effective date missing' unless params[:effective_date]
        errors << 'eligibility item missing' unless params[:eligibility_item]

        errors.empty? ? Success(params) : Failure(errors)
      end

      def evidence_items_for(values)
        eligibility_item = values[:eligibility_item]

        eligibility_item.evidence_items.select do |evidence_item|
          values[:evidence_item_keys].blank? ||
            values[:evidence_item_keys].include?(evidence_item.key.to_sym)
        end
      end

      def evidence_states_for(values)
        evidence_items_for(values)
          .collect do |evidence_item|
            attrs = values.slice(:subject, :effective_date, :eligibility_item).merge(evidence_item: evidence_item)
            evidence_state = Operations::Eligibilities::BuildEvidenceState.new.call(attrs)
            evidence_state.success? ? evidence_state.success : {}
          end
          .compact
          .reduce(:merge)
      end

      def build_eligibility_state(values)
        evidence_states = evidence_states_for(values)
        evidence_states.delete_if do |_evidence_key, evidence_state|
          evidence_state.empty?
        end

        eligibility_state = {
          determined_at: DateTime.now,
          evidence_states: evidence_states
        }

        if values[:eligibility_item].key == 'aptc_csr_credit'
          subject = GlobalID::Locator.locate(values[:subject])
          grants = build_csr_grants(subject, values[:effective_date]).success
          eligibility_state.merge!(grants: grants)
        end

        if evidence_states.present?
          eligibility_state.merge!(
            {
              is_eligible: fetch_status(evidence_states),
              earliest_due_date: fetch_earliest_due_date(evidence_states),
              document_status: fetch_document_status(evidence_states)
            }
          )
        end

        Success(eligibility_state)
      end

      def build_csr_grants(family_member, effective_date)
        Operations::Eligibilities::BuildGrant.new.call(
          family_member: family_member,
          family: family_member.family,
          type: 'CsrAdjustmentGrant',
          effective_date: effective_date
        )
      end

      def fetch_document_status(evidence_states)
        evidence_statuses = evidence_states.values.collect { |evidence_state| evidence_state[:status] }
        non_verified_states = evidence_statuses.reject {|status| ['verified', 'attested', 'determined'].include?(status)}

        return 'NA' if non_verified_states.blank?
        return 'Fully Uploaded' if non_verified_states.all?{|status| status == 'review'}
        return 'Partially Uploaded' if non_verified_states.include?('review')
        return 'None' if evidence_statuses.include?('outstanding')

        'NA'
      end

      def fetch_earliest_due_date(evidence_states)
        evidence_to_compare = evidence_states.values.reject{|value| value[:due_on].blank?}
        return nil if evidence_to_compare.empty?

        evidence_to_compare.min_by do |evidence_state|
          evidence_state[:due_on]
        end[
          :due_on
        ]
      end

      def fetch_status(evidence_states)
        evidence_states.values.all? do |evidence_state|
          evidence_state[:is_satisfied]
        end
      end
    end
  end
end
