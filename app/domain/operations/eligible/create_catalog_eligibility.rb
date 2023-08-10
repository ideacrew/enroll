# frozen_string_literal: true

require "dry/monads"
require "dry/monads/do"

module Operations
  module Eligible
    # Dependency injection class for Catalog Eligibility
    class CatalogEligibilityOptions < EligibilityConfiguration
      def initialize(feature)
        @feature = feature
        super()
      end

      def offered_grants
        @feature
          .setting(:grants_offered)
          .item
          .select do |grant_feature_key|
            EnrollRegistry.feature?(grant_feature_key)
          end
      end

      def grants
        offered_grants.collect do |grant_feature_key|
          [grant_feature_key, EnrollRegistry[grant_feature_key].enabled?]
        end
      end

      def key
        @feature.key.to_s
      end

      def title
        key.titleize
      end
    end

    # Dependency injection class for Catalog Evidence
    class CatalogEvidenceOptions < EvidenceConfiguration
      def initialize(feature)
        @feature = feature
        super()
      end

      def key
        "#{@feature.key}_evidence"
      end

      def title
        key.titleize
      end
    end

    # Operation to support yearly catalog eligibility configuration creation
    class CreateCatalogEligibility
      send(:include, Dry::Monads[:result, :do])

      attr_reader :subject, :calender_year, :eligibility_feature

      # @param [Hash] opts Options to Create Eligibility Configuration
      # @option opts [GlobalId] :subject required
      # @option opts [String]   :eligibility_feature required
      # @option opts [String]   :effective_date required
      # @option opts [String]   :domain_model required
      # @return [Dry::Monad] result
      def call(params)
        values = yield validate(params)
        eligibility = yield build(values)
        eligibility_entity = yield create(values, eligibility)
        eligibility_record = yield persist(eligibility_entity)

        Success(eligibility_record)
      end

      private

      def validate(params)
        errors = []
        errors << "subject missing" unless params[:subject]
        @subject = GlobalID::Locator.locate(params[:subject])
        errors << "effective_date missing" unless params[:effective_date]

        errors << "unable to find subject: #{params[:subject]}" unless @subject.present?
        errors << "domain model missing" unless params[:domain_model]
        errors << "eligibility feature missing" unless params[:eligibility_feature]

        @calender_year = params[:effective_date].year
        if EnrollRegistry.feature?(
          "#{params[:eligibility_feature]}_#{calender_year}"
        )
          @eligibility_feature =
            EnrollRegistry[
              "#{params[:eligibility_feature]}_#{calender_year}".to_sym
            ]
        else
          errors << "unable to find feature: #{params[:eligibility_feature]}_#{calender_year}"
        end

        errors.empty? ? Success(params) : Failure(errors)
      end

      def build(_values)
        options = {
          subject: subject.to_global_id,
          evidence_key: "#{eligibility_feature.key}_evidence",
          evidence_value: eligibility_feature.enabled?.to_s,
          effective_date: values[:effective_date]
        }

        ::Operations::Eligible::BuildEligibility.new(
          configuration: CatalogEligibilityOptions.new(eligibility_feature)
        ).call(
          options.merge(
            evidence_configuration:
              CatalogEvidenceOptions.new(eligibility_feature)
          )
        )
      end

      def create(values, eligibility)
        AcaEntities::Eligible::AddEligibility.new.call(
          subject: values[:domain_model],
          eligibility: eligibility
        )
      end

      def persist(eligibility_entity)
        eligibility_params = eligibility_entity.to_h.except(:evidences, :grants)
        eligibility_record = ::Eligible::Eligibility.new(eligibility_params)
        eligibility_record.tap do |record|
          record.evidences =
            record.class.create_objects(
              eligibility_entity.evidences,
              :evidences
            )
          record.grants =
            record.class.create_objects(eligibility_entity.grants, :grants)
        end

        subject.eligibilities << eligibility_record

        subject.save ? Success(eligibility_record) : Failure(subject.errors)
      end
    end
  end
end
