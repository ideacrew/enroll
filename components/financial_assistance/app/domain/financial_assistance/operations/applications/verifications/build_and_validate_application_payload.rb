# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module FinancialAssistance
  module Operations
    module Applications
      module Verifications
        # This class is responsible for validating an application object and constructing a payload entity for FDSH service.
        class BuildAndValidateApplicationPayload
          include Dry::Monads[:result, :do]

          def call(application, can_check_rules: true)
            cv3_application = yield construct_cv3_application(application)
            payload_entity = yield construct_payload_entity(cv3_application)
            yield check_eligibility_rules(payload_entity) if can_check_rules && EnrollRegistry.feature_enabled?(:validate_and_record_publish_application_errors)

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

          def check_eligibility_rules(payload)
            applicant_array = payload.applicants.map do |applicant|
              valid = ::FinancialAssistance::Operations::Applications::Verifications::CheckEligibilityRules.new.call(applicant)

              # unless valid
                # check for income_evidence -> mark appropriately (aptc/csr)
                # check for esi_evidence -> mark attested 
                # check for non_esi_evidence -> mark attested 
                # check for local_mec_evidence -> mark attested 
                # add verification histories to all
              # end

            end
            # return Failure('no valid applicants') if applicant_array.all? { |applicant| applicant.failure? }
            Success()
          end
        end
      end
    end
  end
end