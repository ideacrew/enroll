# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
require 'aca_entities/magi_medicaid/libraries/iap_library'

module FinancialAssistance
  module Operations
    module Applications
      module MedicaidGateway
        #medicaid Gateway
        class RequestEligibilityDetermination
          # Requests eligibility determination from medicaid gateway

          include Dry::Monads[:result, :do]
          include Acapi::Notifiers

          # @param [Hash] opts The options to request eligibility determination from MedicaidGateway system
          # @option opts [BSON::ObjectId] :application_id id ofFinancialAssistance::Application
          # @return [Dry::Monads::Result]
          def call(application_id:)
            application    = yield find_application(application_id)
            application    = yield validate(application)
            payload_param  = yield construct_payload(application)
            payload_value  = yield validate_payload(payload_param)
            _application   = yield update_application(application, payload_value)
            payload        = yield publish(payload_value)

            Success(payload)
          end

          private

          def find_application(application_id)
            application = FinancialAssistance::Application.find(application_id)

            Success(application)
          rescue Mongoid::Errors::DocumentNotFound
            Failure("Unable to find Application with ID #{application_id}.")
          end

          def validate(application)
            return Success(application) if application.submitted?
            Failure("Application is in #{application.aasm_state} state. Please submit application.")
          end

          def construct_payload(application)
            FinancialAssistance::Operations::Applications::Transformers::ApplicationTo::Cv3Application.new.call(application)
          rescue StandardError => e
            Failure(e)
          end

          def update_application(application, payload_value)
            application.assign_attributes({ eligibility_request_payload: payload_value.to_h.to_json })
            return Success(application) if application.save
            Failure("Unable to update application(hbx_id: #{application.hbx_id}) with eligibility_request_payload")
          end

          def validate_payload(payload)
            AcaEntities::MagiMedicaid::Operations::InitializeApplication.new.call(payload)
          end

          def publish(payload)
            FinancialAssistance::Operations::Applications::MedicaidGateway::PublishApplication.new.call(
              payload: payload.to_h,
              event_name: 'determine_eligibility'
            )
          end
        end
      end
    end
  end
end
