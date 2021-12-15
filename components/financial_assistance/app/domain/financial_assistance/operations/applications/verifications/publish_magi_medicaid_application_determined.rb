# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
require 'aca_entities/magi_medicaid/libraries/iap_library'

module FinancialAssistance
  module Operations
    module Applications
      module Verifications
          # Requests FDSH for ESI, NON ESI and IFSV
        class PublishMagiMedicaidApplicationDetermined

          include Dry::Monads[:result, :do]
          include Acapi::Notifiers

          # @param [ Hash ] params Applicant Attributes
          # @return [ BenefitMarkets::Entities::Applicant ] applicant Applicant
          def call(application)
            valid_application  = yield validate_application(application)
            payload_param      = yield construct_payload(valid_application)
            payload_value      = yield validate_payload(payload_param)
            payload            = yield publish(payload_value, valid_application.id)

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
            FinancialAssistance::Operations::Applications::Transformers::ApplicationTo::Cv3Application.new.call(application)
          end

          def validate_payload(payload)
            AcaEntities::MagiMedicaid::Operations::InitializeApplication.new.call(payload)
          end

          def publish(payload, application_id)
            FinancialAssistance::Operations::Applications::Verifications::MagiMedicaidApplicationDetermined.new.call(payload, application_id)
          end
        end
      end
    end
  end
end
