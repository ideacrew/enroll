# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
require 'aca_entities/magi_medicaid/libraries/iap_library'

module FinancialAssistance
  module Operations
    module Applications
      module MedicaidGateway
        # medicaid Gateway
        class RequestMecChecks
          # Requests MEC Checks for an entire application from Medicaid Gateway

          include Dry::Monads[:do, :result]
          include Acapi::Notifiers

          def call(application_id:, transmittable_message_id: nil)
            application    = yield find_application(application_id)
            payload_param  = yield construct_payload(application)
            payload_value  = yield validate_payload(payload_param)
            payload        = yield publish(payload_value, transmittable_message_id)

            Success(payload)
          end

          private

          def find_application(application_id)
            application = FinancialAssistance::Application.find(application_id)

            Success(application)
          rescue Mongoid::Errors::DocumentNotFound
            Failure("Unable to find Application with ID #{application_id}.")
          end

          def construct_payload(application)
            result = FinancialAssistance::Operations::Applications::Transformers::ApplicationTo::Cv3Application.new.call(application)
            result.success? ? result : Failure("Failed to construct payload: #{result.failure}")
          end

          def validate_payload(payload)
            AcaEntities::MagiMedicaid::Operations::InitializeApplication.new.call(payload)
          end

          def publish(payload, transmittable_message_id)
            FinancialAssistance::Operations::Applications::MedicaidGateway::PublishMecCheck.new.call(payload.to_h, "application", transmittable_message_id)
          end

        end
      end
    end
  end
end
