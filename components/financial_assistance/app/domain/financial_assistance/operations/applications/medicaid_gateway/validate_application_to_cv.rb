# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
require 'aca_entities/magi_medicaid/libraries/iap_library'

module FinancialAssistance
  module Operations
    module Applications
      module MedicaidGateway
        #medicaid Gateway
        class ValidateApplicationToCv
          # Validate CV3 payload for applications
          include Dry::Monads[:do, :result]

          # @param [Hash] opts The options to validate applications
          # @option opts [BSON::ObjectId] :application_id id ofFinancialAssistance::Application
          # @return [Dry::Monads::Result]
          def call(application_id:)
            application    = yield find_application(application_id)
            # valid_application = yield validate(application)
            payload_param  = yield construct_payload(application)
            payload_value  = yield validate_payload(payload_param)

            Success(payload_value)
          end

          private

          def find_application(application_id)
            application = FinancialAssistance::Application.find(application_id)

            Success(application)
          rescue Mongoid::Errors::DocumentNotFound
            Failure("Unable to find Application with ID #{application_id}.")
          end

          def validate(application)
            return Success(application) if application.imported?
            Failure("Application not in imported state. instead it's in #{application.aasm_state}")
          end

          def construct_payload(application)
            FinancialAssistance::Operations::Applications::Transformers::ApplicationTo::Cv3Application.new.call(application)
          end

          def validate_payload(payload)
            result = ::AcaEntities::MagiMedicaid::Contracts::ApplicationContract.new.call(payload)

            if result.success?
              Success(result.to_h)
            else
              Failure(result)
            end
          end
        end
      end
    end
  end
end
