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

          include Dry::Monads[:do, :result]
          include Acapi::Notifiers

          # @param [Hash] opts The options to request eligibility determination from MedicaidGateway system
          # @option opts [BSON::ObjectId] :application_id id ofFinancialAssistance::Application
          # @return [Dry::Monads::Result]
          def call(application_id:)
            application    = yield find_application(application_id)
            application    = yield validate(application)
            application    = yield submit_application(application)
            payload_param  = yield construct_payload(application)
            payload_value  = yield validate_payload(payload_param)
            _application   = yield update_application(application, payload_value)
            payload        = yield publish_event(payload_value)

            Success(payload)
          end

          private

          def find_application(application_id)
            application = FinancialAssistance::Application.find(application_id)

            Success(application)
          rescue Mongoid::Errors::DocumentNotFound
            Failure("Unable to find Application with ID #{application_id}.")
          end

          def submit_application(application)
            application.submit
            return Success(application) if application.save
            Failure("Unable to save the application for given application hbx_id: #{application.hbx_id}, base_errors: #{application.errors.to_hash}")
          rescue StandardError => e
            Failure("Submission failed for the application id: #{application.id} | backtrace: #{e}")
          end

          def validate(application)
            return Success(application) if application.may_submit?
            Failure("Unable to submit the application for given application hbx_id: #{application.hbx_id}, base_errors: #{application.errors.to_hash}")
          end

          def construct_payload(application)
            if application.submitted?
              FinancialAssistance::Operations::Applications::Transformers::ApplicationTo::Cv3Application.new.call(application)
            else
              Failure("application is in draft state for the application id: #{application.id}")
            end
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

          def publish_event(payload)
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
