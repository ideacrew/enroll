# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module FinancialAssistance
  module Operations
    module Applications
      # This Operation renews a renewal_draft application i.e. submits a renewal_draft application.
      # Operation receives a persisted renewal_draft FinancialAssistance::Application object.
      class Renew
        include Dry::Monads[:result, :do]

        # @param [Hash] opts The options to submit renewal_draft application
        # @option opts [::FinancialAssistance::Application] :application
        # @return [Dry::Monads::Result]
        def call(renewal_draft_application)
          # verify if application is in renewal_draft aasm state.
          application         = yield check_application_state(renewal_draft_application)
          updated_application = yield add_attestation_data(application)
          renewed_application = yield renew_application(updated_application)

          Success(renewed_application)
        end

        private

        def check_application_state(renewal_draft_application)
          return Failure("Given input: #{renewal_draft_application} is not a valid FinancialAssistance::Application.") unless renewal_draft_application.is_a?(::FinancialAssistance::Application)
          return Failure("Cannot generate renewal_draft for given application with aasm_state #{renewal_draft_application.aasm_state}. Application must be in renewal_draft state.") unless renewal_draft_application.renewal_draft?
          Success(renewal_draft_application)
        end

        # TODO: add attestation data
        def add_attestation_data(application)
          Success(application)
        end

        def renew_application(application)
          return Failure("Given application with hbx_id: #{application.hbx_id} is not valid for submission") unless application.complete?

          if application.submit!
            request_result = determination_request_class.new.call(application_id: application.id)
            request_result.failure? ? request_result : Success(application)
          else
            Failure("Unable to submit the application for given application hbx_id: #{application.hbx_id}")
          end
        end

        def determination_request_class
          return FinancialAssistance::Operations::Application::RequestDetermination if FinancialAssistanceRegistry.feature_enabled?(:haven_determination)
          return FinancialAssistance::Operations::Applications::MedicaidGateway::RequestEligibilityDetermination if FinancialAssistanceRegistry.feature_enabled?(:medicaid_gateway_determination)
        end
      end
    end
  end
end
