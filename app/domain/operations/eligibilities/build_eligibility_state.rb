# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Eligibilities
    class BuildEligibilityState
      send(:include, Dry::Monads[:result, :do])

      # @param [Hash] opts Options to build eligibility state
      # @option opts [GlobalID] :subject required
      # @option opts [AcaEntities::Elgibilities::EligibilityItem] :eligibility_item required
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

      def build_eligibility_state(values)
        eligibility_item = values[:eligibility_item]

        eligibility_state = {
          eligibility_item_key: eligibility_item.key,
          evidence_states: evidence_states_for(values)
        }

        Success(eligibility_state)
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
            attrs =
              values
              .slice(:subject, :effective_date, :eligibility_item)
              .merge(evidence_item: evidence_item)
            evidence_state =
              Operations::Eligibilities::BuildEvidenceState.new.call(attrs)
            evidence_state.success? ? evidence_state.success : {}
          end
          .compact
          .reduce(:merge)
      end
    end
  end
end
