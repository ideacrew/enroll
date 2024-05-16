# frozen_string_literal: true

require "dry/monads"
require "dry/monads/do"

module Operations
  module Eligible
    # Operation to support eligibility creation
    class BuildEligibility
      include Dry::Monads[:do, :result]
      include ::Operations::Eligible::EligibilityImport[
                configuration: "eligibility_defaults"
              ]

      # @param [Hash] opts Options to build eligibility
      # @option opts [<GlobalId>] :subject required
      # @option opts [<String>]   :evidence_key required
      # @option opts [<String>]   :evidence_value required
      # @option opts [Date]       :effective_date required
      # @option opts [ShopOsseEligibility]  :eligibility_record optional
      # @option opts [EvidenceConfiguration]  :evidence_configuration optional
      # @option opts [Hash]       :timestamps optional timestamps for data migrations purposes
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
        errors << "effective date missing or it should be a date" unless params[:effective_date].is_a?(::Date)

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
        options = {}
        options[:configuration] = values[:evidence_configuration] if values[
          :evidence_configuration
        ]
        ::Operations::Eligible::BuildEvidence.new(**options).call(
          values.merge(evidence_record: evidence_record)
        )
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
        new_state_history = build_elgibility_state_history(values, options[:evidences])
        options[:state_histories] << new_state_history
        options[:current_state] = new_state_history[:to_state]

        Success(options)
      end

      def build_default_eligibility_options(values)
        if values[:eligibility_record]&.persisted?
          return(
            values[:eligibility_record].serializable_hash.deep_symbolize_keys
          )
        end

        {
          title: configuration.title,
          key: configuration.key,
          grants: build_grants
        }
      end

      def build_grants
        configuration.grants.compact.collect do |value_pair|
          params = { grant_key: value_pair[0], grant_value: value_pair[1].to_s }
          result = BuildGrant.new.call(params)
          result.success? ? result.value! : nil
        end
      end

      def build_elgibility_state_history(values, evidences_options)
        to_state = configuration.to_state_for(evidences_options)
        from_state =
          values[:eligibility_record]&.state_histories&.last&.to_state

        options = {
          event: "move_to_#{to_state}".to_sym,
          transition_at: DateTime.now,
          effective_on: values[:effective_date],
          from_state: from_state || :initial,
          to_state: to_state,
          is_eligible: (to_state == :eligible)
        }
        options[:timestamps] = values[:timestamps] if values[:timestamps]
        options
      end
    end
  end
end
