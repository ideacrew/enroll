# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
require 'pry'

module FinancialAssistance
  module Operations
    module Applications
      module Haven
        # This Operation renews a renewal_draft application i.e. submits a renewal_draft application.
        class RequestMagiMedicaidEligibilityDetermination
          include Dry::Monads[:result, :do, :try]
          include EventSource::Command

          # @param [Hash] opts The options to submit renewal_draft application
          # @option opts [Hash] :application
          # @return [Dry::Monads::Result]
          def call(params)
            application = yield find_application(params)
            payload = yield renew_application(application)
            event  = yield build_event(payload)
            publish(event)

            Success(application)
          end

          private

          def find_application(params)
            return Failure("Input params is not a hash: #{params}") unless params.is_a?(Hash)
            return Failure('Missing application_id key') unless params.key?("_id")
            application = ::FinancialAssistance::Application.find(params["_id"])
            return Failure("Cannot find Application with input value: #{params["_id"]} for key application_id") unless application
            Success(application)
          end

          def renew_application(application)
            application.set_renewal_base_year
            if application.have_permission_to_renew?
              if application.may_submit?
                application.submit!
              else
                application.fail_submission!
                Rails.logger.error "Unable to submit the application for given application hbx_id: #{application.hbx_id}"
                return Failure("Unable to submit the application for given application hbx_id: #{application.hbx_id}")
              end

              FinancialAssistance::Operations::Application::RequestDetermination.new.call(application_id: application.id)
            else
              Rails.logger.error "Application permission to renew is failed for hbx_id: #{application.hbx_id}"
              Failure("Application permission to renew is failed for hbx_id: #{application.hbx_id}")
            end
          end

          # def haven_determination_is_enabled?
          #   FinancialAssistanceRegistry.feature_enabled?(:haven_determination)
          # end

          # def medicaid_gateway_determination_is_enabled?
          #   FinancialAssistanceRegistry.feature_enabled?(:medicaid_gateway_determination)
          # end

          def build_event(payload)
            event("events.iap.applications.haven_magi_medicaid_eligibility_determination_requested", attributes: {determination: payload})
          end

          def publish(event)
            event.publish

            Success("Successfully published the payload for event: 'haven_magi_medicaid_eligibility_determination_requested'")
          end
        end
      end
    end
  end
end
