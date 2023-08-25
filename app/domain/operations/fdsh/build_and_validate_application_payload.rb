# frozen_string_literal: true

module Operations
  module Fdsh
    # This class is responsible for validating an application object and constructing a payload entity for FDSH service.
    class BuildAndValidateApplicationPayload
      include Dry::Monads[:result, :do, :try]

      def call(application, request_type, can_check_rules: true)
        cv3_application = yield construct_cv3_application(application)
        payload_entity = yield construct_payload_entity(cv3_application)
        yield check_eligibility_rules(payload_entity.success, request_type) if can_check_rules && EnrollRegistry.feature_enabled?(:validate_income_evidence_and_record_publish_errors)
        binding.irb
        Success(payload_entity)
      end

      private

      def construct_cv3_application(application)
        if application.is_a?(::FinancialAssistance::Application)
          ::FinancialAssistance::Operations::Applications::Transformers::ApplicationTo::Cv3Application.new.call(application)
        else
          Failure("Could not generate CV3 Application Object with #{application}")
        end
      end

      def construct_payload_entity(cv3_application)
        result = AcaEntities::MagiMedicaid::Operations::InitializeApplication.new.call(cv3_application)
        # add addtl validation here?
        Success(result)
      end

      def check_eligibility_rules(payload, request_type)
        Operations::Fdsh::PayloadEligibility::CheckApplicationEligibilityRules.new.call(payload, request_type)
      end
    end
  end
end