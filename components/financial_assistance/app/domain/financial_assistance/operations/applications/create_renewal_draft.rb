# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module FinancialAssistance
  module Operations
    module Applications
      # This Operation creates a new renewal_draft application from a given FinancialAssistance::Application,
      # if the given application is eligible.
      # Operation receives a persisted FinancialAssistance::Application object
      class CreateRenewalDraft
        include Dry::Monads[:result, :do]

        # @param [Hash] opts The options to generate renewal_draft application
        # @option opts [::FinancialAssistance::Application] :application
        # @return [Dry::Monads::Result]
        def call(application)
          # verify if application is in determined aasm state.
          determined_application = yield check_application_state(application)
          renewal_draft_app      = yield create_renewal_draft_application(determined_application)

          Success(renewal_draft_app)
        end

        private

        def check_application_state(application)
          return Failure("Given input: #{application} is not a valid FinancialAssistance::Application.") unless application.is_a?(::FinancialAssistance::Application)
          return Failure("Cannot generate renewal_draft for given application with aasm_state #{application.aasm_state}. Application must be in determined state.") unless application.determined?
          Success(application)
        end

        def create_renewal_draft_application(application)
          service = ::FinancialAssistance::Services::ApplicationService.new(application_id: application.id)
          draft_app = service.copy!
          # Using update attributes instead of calling aasm event becuase 'renewal_draft' is the first state for a renewal application.
          draft_app.update_attributes!(aasm_state: 'renewal_draft', assistance_year: application.assistance_year.next)
          Success(draft_app)
        rescue StandardError => e
          Rails.logger.error "---CreateRenewalDraft: Unable to generate Renewal Draft Application for application with hbx_id: #{application.hbx_id}, error: #{e.backtrace}"
          Failure("Could not generate renewal draft for given application with hbx_id: #{application.hbx_id}, error: #{e.message}")
        end
      end
    end
  end
end
