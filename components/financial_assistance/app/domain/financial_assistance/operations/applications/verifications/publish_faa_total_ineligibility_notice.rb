# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
require 'aca_entities/magi_medicaid/libraries/iap_library'

module FinancialAssistance
  module Operations
    module Applications
      module Verifications
          # Notifies families of totally ineligible members
        class PublishFaaTotalIneligibilityNotice

          include Dry::Monads[:do, :result]
          include Acapi::Notifiers

          # @param [ Hash ] params Applicant Attributes
          # @return [ BenefitMarkets::Entities::Applicant ] applicant Applicant
          def call(application)
            valid_application  = yield validate_application(application)
            payload_value      = yield construct_payload(valid_application)
            payload            = yield publish(payload_value)

            Success(payload)
          end

          private

          def validate_application(application)
            if application.is_a?(FinancialAssistance::Application)
              Success(application)
            else
              Failure("Invalid Application object #{application}, expected FinancialAssistance::Application")
            end
          end

          def construct_payload(application)
            if application.determined? && application.eligibility_response_payload.present?
              parsed_payload = JSON.parse(application.eligibility_response_payload, symbolize_names: true)
              ::AcaEntities::MagiMedicaid::Operations::InitializeApplication.new.call(parsed_payload)
            else
              Failure("PublishFaaTotalIneligibilityNotice_error: Could not initialize application for undetermined application #{application.id}")
            end
          end

          def publish(payload)
            FinancialAssistance::Operations::Applications::Verifications::FaaTotalIneligibilityNotice.new.call(payload.to_h)
          end
        end
      end
    end
  end
end
