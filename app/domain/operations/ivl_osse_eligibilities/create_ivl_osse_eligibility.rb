# frozen_string_literal: true

require "dry/monads"
require "dry/monads/do"

module Operations
  module IvlOsseEligibilities
    # Operation to support IVL osse eligibility creation
    class CreateIvlOsseEligibility
      send(:include, Dry::Monads[:result, :do])

      attr_reader :subject

      # @param [Hash] opts Options to build eligibility
      # @option opts [<GlobalId>] :subject required
      # @option opts [<String>]   :evidence_key required
      # @option opts [<String>]   :evidence_value required
      # @option opts [Date]       :effective_date required
      # @option opts [Hash]       :timestamps optional timestamps for data migrations purposes
      # @return [Dry::Monad] result
      def call(params)
        values = yield validate(params)
        eligibility_record = yield find_eligibility(values)
        eligibility_options =
          yield build_eligibility_options(values, eligibility_record)
        eligibility = yield create_eligibility(values, eligibility_options)
        persisted_eligibility = yield store(values, eligibility)

        Success(persisted_eligibility)
      end

      private

      def validate(params)
        params[:effective_date] ||= TimeKeeper.date_of_record

        errors = []
        errors << "evidence key missing" unless params[:evidence_key]
        errors << "evidence value missing" unless params[:evidence_value]
        unless params[:effective_date].is_a?(::Date)
          errors << "effective date missing or it should be a date"
        end
        @subject = GlobalID::Locator.locate(params[:subject])
        unless subject.present?
          errors << "subject missing or not found for #{params[:subject]}"
        end

        errors.empty? ? Success(params) : Failure(errors)
      end

      # For a given calendar year there will be only one instance of OSSE eligibility with only one evidence instance.
      # We'll be adding State Histories when the eligibility changes
      def find_eligibility(values)
        eligibility =
          subject.find_eligibility_by(
            "aca_ivl_osse_eligibility_#{values[:effective_date].year}".to_sym
          )

        Success(eligibility)
      end

      def build_eligibility_options(values, eligibility_record = nil)
        ::Operations::Eligible::BuildEligibility.new(
          configuration:
            ::Operations::IvlOsseEligibilities::OsseEligibilityConfiguration.new(
              values[:effective_date]
            )
        ).call(
          values.merge(
            eligibility_record: eligibility_record,
            evidence_configuration:
              ::Operations::IvlOsseEligibilities::OsseEvidenceConfiguration.new
          )
        )
      end

      # Following Operation expects AcaEntities domain class as subject
      def create_eligibility(_values, eligibility_options)
        AcaEntities::Eligible::AddEligibility.new.call(
          subject: "AcaEntities::People::#{subject.class.to_s.demodulize}",
          eligibility: eligibility_options
        )
      end

      def store(_values, eligibility)
        eligibility_record =
          subject.eligibilities.where(id: eligibility._id).first

        if eligibility_record
          update_eligibility_record(eligibility_record, eligibility)
        else
          eligibility_record = create_eligibility_record(eligibility)
          subject.eligibilities << eligibility_record
        end

        if subject.save
          Success(eligibility_record)
        else
          Failure(subject.errors.full_messages)
        end
      end

      def update_eligibility_record(eligibility_record, eligibility)
        evidence = eligibility.evidences.last
        evidence_history_params = build_history_params_for(evidence)
        eligibility_history_params = build_history_params_for(eligibility)

        evidence_record = eligibility_record.evidences.last
        evidence_record.is_satisfied = evidence.is_satisfied
        evidence_record.current_state = evidence.current_state
        evidence_record.state_histories.build(evidence_history_params)
        eligibility_record.state_histories.build(eligibility_history_params)
        eligibility_record.current_state = eligibility.current_state

        eligibility_record.save
        subject.save
      end

      def build_history_params_for(record)
        record_history = record.state_histories.last
        record_history.to_h
      end

      def create_eligibility_record(eligibility)
        osse_eligibility_params = eligibility.to_h.except(:evidences, :grants)

        eligibility_record =
          ::IvlOsseEligibilities::IvlOsseEligibility.new(
            osse_eligibility_params
          )

        eligibility_record.tap do |record|
          record.evidences =
            record.class.create_objects(eligibility.evidences, :evidences)
          record.grants =
            record.class.create_objects(eligibility.grants, :grants)
        end

        eligibility_record
      end
    end
  end
end
