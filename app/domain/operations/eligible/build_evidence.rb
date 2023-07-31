# frozen_string_literal: true

require "dry/monads"
require "dry/monads/do"

module Operations
  module Eligible
    # Operation to support eligibility creation
    class BuildEvidence
      send(:include, Dry::Monads[:result, :do])

      ELIGIBLE_STATUSES = %i[approved].freeze
      EVENTS = %i[move_to_initial move_to_approved move_to_denied].freeze

      STATE_MAPPING = {
        initial: [:initial],
        approved: %i[initial denied],
        denied: %i[approved]
      }.freeze

      # @param [Hash] opts Options to build eligibility
      # @option opts [<GlobalId>] :subject required
      # @option opts [<String>]   :evidence_key required
      # @option opts [<String>]   :evidence_value required
      # @option opts [Date]       :effective_date required
      # @option opts [Date]       :evidence_record optional
      # @return [Dry::Monad] result
      def call(params)
        values = yield validate(params)
        evidence_options = yield build(values)

        Success(evidence_options)
      end

      private

      def validate(params)
        errors = []
        errors << "subject missing" unless params[:subject]
        errors << "evidence key missing" unless params[:evidence_key]
        errors << "evidence value missing" unless params[:evidence_value]
        errors << "effective date missing" unless params[:effective_date]

        errors.empty? ? Success(params) : Failure(errors)
      end

      def build(values)
        options = build_default_evidence_options(values)
        state_history_options = build_state_history(values)

        options[:state_histories] ||= []
        options[:state_histories] << state_history_options
        options[:is_satisfied] = state_history_options[:is_eligible]

        Success(options)
      end

      def build_default_evidence_options(values)
        if values[:evidence_record]&.persisted?
          options =
            values[:evidence_record].serializable_hash.deep_symbolize_keys
          options[:subject_ref] = URI(options[:subject_ref]) unless options[
            :subject_ref
          ].is_a? URI
          options[:evidence_ref] = URI(options[:evidence_ref]) unless options[
            :evidence_ref
          ].is_a? URI
          options
        else
          {
            title: values[:evidence_key].to_s.titleize,
            key: values[:evidence_key].to_sym,
            subject_ref: values[:subject].uri,
            evidence_ref:
              URI("gid://enroll_app/BenefitSponsorships/ShopOsseEvidence") # FIXME
          }
        end
      end

      def build_state_history(values)
        recent_record =
          values[:evidence_record]&.state_histories&.max_by(&:created_at)
        from_state = recent_record&.to_state || :initial
        to_state = to_state_for(values, from_state)

        options = {
          event: "move_to_#{to_state}".to_sym,
          transition_at: DateTime.now,
          effective_on: values[:effective_date],
          from_state: from_state,
          to_state: to_state
        }

        options[:is_eligible] = ELIGIBLE_STATUSES.include?(
          options[:to_state]
        ) if options[:to_state]
        options
      end

      def to_state(event)
        event.to_s.match(/move_to_(.*)/)[1].to_sym
      end

      def to_state_for(values, from_state)
        evidence_value = values[:evidence_value]

        if evidence_value == "true"
          :approved
        elsif evidence_value == "false"
          if from_state == :approved
            :denied
          elsif from_state == :initial
            return :initial unless values[:evidence_record]
            :denied
          end
        end
      end
    end
  end
end
