# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module FinancialAssistance
  module Operations
    module Applications
      # This Operation renews a renewal_draft application i.e. submits a renewal_draft application.
      class Renew
        include Dry::Monads[:result, :do]

        # @param [Hash] opts The options to submit renewal_draft application
        # @option opts [String] :application_hbx_id
        # @return [Dry::Monads::Result]
        def call(params)
          # verify if application is in renewal_draft aasm state.
          application         = yield find_application(params)
          _state_check        = yield check_application_state(application)
          _result             = yield check_if_eligible_for_renewal(application)
          renewed_application = yield renew_application(application)

          Success(renewed_application)
        end

        private

        def find_application(params)
          return Failure("Input params is not a hash: #{params}") unless params.is_a?(Hash)
          return Failure('Missing application_hbx_id key') unless params.key?(:application_hbx_id)
          appli = ::FinancialAssistance::Application.by_hbx_id(params[:application_hbx_id]).first
          return Failure("Cannot find Application with input value: #{params[:application_hbx_id]} for key application_hbx_id") if appli.nil?

          Success(appli)
        end

        def check_application_state(renewal_draft_application)
          return Failure("Given input: #{renewal_draft_application} is not a valid FinancialAssistance::Application.") unless renewal_draft_application.is_a?(::FinancialAssistance::Application)
          return Failure("Cannot generate renewal_draft for given application with aasm_state #{renewal_draft_application.aasm_state}. Application must be in renewal_draft state.") unless renewal_draft_application.renewal_draft?
          Success(renewal_draft_application)
        end

        # Validate in terms of submission & check for attestations
        def check_if_eligible_for_renewal(application)
          return Success(application) if application.complete? && application.attesations_complete?
          Failure("Application with hbx_id: #{application.hbx_id} is incomplete(validations/attestations) for submission.")
        end

        def renew_application(application)
          # Set Renewal Base Year before submission, then check if we have permission to renew the application.
          application.set_renewal_base_year
          if application.have_permission_to_renew? && application.submit!
            request_result = determination_request_class.new.call(application_id: application.id)
            request_result.failure? ? request_result : Success(application)
          else
            application.fail_submission!
            Failure("Expired Submission or unable to submit the application for given application hbx_id: #{application.hbx_id}")
          end
        end

        def determination_request_class
          return FinancialAssistance::Operations::Application::RequestDetermination if haven_determination_is_enabled
          return FinancialAssistance::Operations::Applications::MedicaidGateway::RequestEligibilityDetermination if medicaid_gateway_determination_is_enabled?
        end

        def haven_determination_is_enabled
          FinancialAssistanceRegistry.feature_enabled?(:haven_determination)
        end

        def medicaid_gateway_determination_is_enabled?
          FinancialAssistanceRegistry.feature_enabled?(:medicaid_gateway_determination)
        end
      end
    end
  end
end
