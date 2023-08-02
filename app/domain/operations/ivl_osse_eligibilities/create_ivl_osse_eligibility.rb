# frozen_string_literal: true

require "dry/monads"
require "dry/monads/do"

module Operations
  module IvlOsseEligibilities
    # Operation to support IVL osse eligibility creation
    class CreateIvlOsseEligibility
      send(:include, Dry::Monads[:result, :do])

      # @param [Hash] opts Options to build eligibility
      # @option opts [<GlobalId>] :subject required
      # @option opts [<String>]   :evidence_key required
      # @option opts [<String>]   :evidence_value required
      # @option opts [Date]       :effective_date required
      # @return [Dry::Monad] result
      def call(params)
        values                = yield validate(params)
        eligibility_record    = yield find_eligibility(values)
        eligibility_options   = yield build_eligibility_options(values, eligibility_record)
        eligibility           = yield create_eligibility(values, eligibility_options)
        persisted_eligibility = yield store(values, eligibility)

        Success(persisted_eligibility)
      end

      private

      def validate(params)
        params[:event] ||= :initialize
        params[:effective_date] ||= TimeKeeper.date_of_record

        params[:effective_date] = params[:effective_date].beginning_of_year if EnrollRegistry.feature_enabled?("aca_ivl_osse_effective_beginning_of_year")

        errors = []
        errors << "subject missing" unless params[:subject]
        errors << "evidence key missing" unless params[:evidence_key]
        errors << "evidence value missing" unless params[:evidence_value]
        errors << "effective date missing" unless params[:effective_date]

        errors.empty? ? Success(params) : Failure(errors)
      end

      def find_eligibility(values)
        subject = GlobalID::Locator.locate(values[:subject])
        eligibility = subject.ivl_eligibilities.by_key(:ivl_osse_eligibility).last

        Success(eligibility)
      end

      def build_eligibility_options(values, eligibility_record = nil)
        ::Operations::Eligible::BuildEligibility.new(
          configuration:
            ::Operations::IvlOsseEligibilities::OsseEligibilityConfiguration
        ).call(
          values.merge(
            eligibility_record: eligibility_record,
            evidence_configuration:
              ::Operations::IvlOsseEligibilities::OsseEvidenceConfiguration
          )
        )
      end

      # Following Operation expects AcaEntities domain class as subject
      def create_eligibility(values, eligibility_options)
        subject = GlobalID::Locator.locate(values[:subject])
        AcaEntities::Eligible::AddEligibility.new.call(
          subject: "AcaEntities::People::#{subject.class.to_s.demodulize}",
          eligibility: eligibility_options
        )
      end

      def store(values, eligibility)
        subject = GlobalID::Locator.locate(values[:subject])

        eligibility_record = subject.ivl_eligibilities.where(id: eligibility._id).first

        if eligibility_record
          update_eligibility_record(eligibility_record, eligibility)
        else
          eligibility_record = create_eligibility_record(eligibility)
          subject.ivl_eligibilities << eligibility_record
        end

        if subject.save
          Success(eligibility_record)
        else
          Failure(subject.errors.full_messages)
        end
      end

      def update_eligibility_record(eligibility_record, eligibility)
        evidence = eligibility.evidences.last
        eligibility_record.evidences.last.state_histories.build(evidence.state_histories.last.to_h)
        eligibility_record.evidences.last.is_satisfied = evidence.is_satisfied
        eligibility_record.state_histories.build(eligibility.state_histories.last.to_h)

        eligibility_record.save
      end

      def create_eligibility_record(eligibility)
        osse_eligibility_params = eligibility.to_h.except(:evidences, :grants)

        eligibility_record = ::IvlOsseEligibilities::IvlOsseEligibility.new(osse_eligibility_params)

        eligibility_record.tap do |record|
          record.evidences = record.class.create_objects(eligibility.evidences, :evidences)
          record.grants = record.class.create_objects(eligibility.grants, :grants)
        end

        eligibility_record
      end
    end
  end
end