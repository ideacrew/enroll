# frozen_string_literal: true

require "dry/monads"
require "dry/monads/do"

module Operations
  module Eligible
    # Operation to support eligibility creation
    class BuildEligibility
      send(:include, Dry::Monads[:result, :do])

      # @param [Hash] opts Options to build eligibility
      # @option opts [<GlobalId>] :subject required
      # @option opts [<String>]   :evidence_key required
      # @option opts [<String>]   :evidence_value required
      # @option opts [Date]       :effective_date required
      # @option opts [ShopOsseEligibility]  :eligibility_record optional
      # @return [Dry::Monad] result
      def call(params)
        values = yield validate(params)
        evidence_record = yield find_evidence(values)
        evidence_options = yield build_evidence_options(values, evidence_record)
        eligibility_options =
          yield build_eligibility_options(values, evidence_options)

        Success(eligibility_options)
      end

      private

      def validate(params)
        errors = []
        errors << "subject missing" unless params[:subject]
        errors << "evidence key missing" unless params[:evidence_key]
        errors << "evidence value missing" unless params[:evidence_value]
        errors << "effective date missing" unless params[:effective_date]
        errors << "eligibility_key is missing" unless params[:eligibility_key]

        errors.empty? ? Success(params) : Failure(errors)
      end

      def find_evidence(values)
        eligibility_rec = values[:eligibility_record]

        return Success(nil) unless eligibility_rec
        Success(
          eligibility_rec
            .evidences
            .by_key(values[:evidence_key])
            .max_by(&:created_at)
        )
      end

      def build_evidence_options(values, evidence_record = nil)
        BuildEvidence.new.call(values.merge(evidence_record: evidence_record))
      end

      def build_eligibility_options(values, evidence_options)
        options = build_default_eligibility_options(values)

        if options[:evidences].present?
          index =
            options[:evidences].index do |e|
              e[:_id].to_s == evidence_options[:_id].to_s
            end
        end
        if index
          options[:evidences][index] = evidence_options
        else
          options[:evidences] = [evidence_options]
        end

        options[:state_histories] ||= []
        options[:state_histories] << build_state_history(
          values,
          evidence_options
        )

        Success(options)
      end

      def build_default_eligibility_options(values)
        if values[:eligibility_record]&.persisted?
          return(
            values[:eligibility_record].serializable_hash.deep_symbolize_keys
          )
        end

        {
          title: values[:eligibility_key].to_s.titleize,
          key: values[:eligibility_key],
          grants: build_grants
        }
      end

      def build_grants
        %i[
          contribution_subsidy_grant
          min_employee_participation_relaxed_grant
          min_fte_count_relaxed_grant
          min_contribution_relaxed_grant
          metal_level_products_restricted_grant
        ].map do |key|
          BuildGrant.new.call(grant_key: key, grant_value: true).success
        end
      end

      def build_state_history(values, evidence_options)
        eligibility_event = eligibility_event_for(evidence_options)
        from_state =
          values[:eligibility_record]&.state_histories&.last&.to_state

        {
          event: eligibility_event,
          transition_at: DateTime.now,
          effective_on: values[:effective_date],
          from_state: from_state || :initial,
          to_state: to_state(eligibility_event),
          is_eligible: evidence_options[:is_satisfied]
        }
      end

      def eligibility_event_for(evidence_options)
        latest_history = evidence_options[:state_histories].last

        case latest_history[:to_state]
        when :approved, :denied
          :move_to_published
        else
          :move_to_initial
        end
      end

      def to_state(event)
        event.to_s.match(/move_to_(.*)/)[1].to_sym
      end
    end
  end
end
