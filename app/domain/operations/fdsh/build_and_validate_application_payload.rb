# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Fdsh
    # This class is responsible for validating an application object and constructing a payload entity for FDSH service.
    class BuildAndValidateApplicationPayload
      include Dry::Monads[:result, :do]

      def call(application)
        cv3_application = yield construct_cv3_application(application)
        payload_entity = yield construct_payload_entity(cv3_application)
        # yield check_eligibility_rules(payload_entity, request_type) if can_check_rules && EnrollRegistry.feature_enabled?(:validate_and_record_publish_application_errors)

        Success(payload_entity)
      end

      private

      def construct_cv3_application(application)
        if application.is_a?(::FinancialAssistance::Application)

          begin
            ::FinancialAssistance::Operations::Applications::Transformers::ApplicationTo::Cv3Application.new.call(application)
          rescue StandardError => e
            Failure(e.message)
          end
        else
          Failure("Could not generate CV3 Application -- wrong object type")
        end
      end

      def construct_payload_entity(cv3_application)
        # the result from the InitializeApplication call here returns a failure if malformed/errors present -- no need to add additional error handling here
        AcaEntities::MagiMedicaid::Operations::InitializeApplication.new.call(cv3_application)
      end

      # def check_eligibility_rules(payload, request_type)
      #   payload.applicants.map do |applicant|
      #     Operations::Fdsh::PayloadEligibility::CheckApplicantEligibilityRules.new.call(applicant, request_type)
      #   end
      # end
    end
  end
end