# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module FinancialAssistance
  module Operations
    module Transfers
      module MedicaidGateway
        # This class is used to automatically submit the application to Medicaid Gateway for determination.
        class AutomaticSubmission
          include Dry::Monads[:do, :result]
          def call(application)
            # Additional steps that may be needed:
            # populate default values for application
            # apply more validations (such as ones that are only enforced in the UI)
            result = yield request_determination(application)
            Success(result)
          end

          def request_determination(application)
            Rails.logger.info "Submitting application #{application.id} to Medicaid Gateway for determination"

            result = FinancialAssistance::Operations::Applications::MedicaidGateway::RequestEligibilityDetermination.new.call(application_id: application.id)
            if result.failure?
              Rails.logger.error "Failed automatic submission for application #{application.id} due to #{result.failure.inspect}"
              return result
            end
            Success(result)
          end
        end
      end
    end
  end
end