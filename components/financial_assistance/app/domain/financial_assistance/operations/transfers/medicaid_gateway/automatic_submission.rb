# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module FinancialAssistance
  module Operations
    module Transfers
      module MedicaidGateway
        # This class is used to automatically submit the application to Medicaid Gateway for determination.
        class AutomaticSubmission
        include Dry::Monads[:result, :do]
          def call(application)
            # add step to populate default values?
            # add step to validate application (consider UI only validations)?
            result = yield request_determination(application)
            Success(result)
          end

          def request_determination(application)
            FinancialAssistance::Operations::Applications::MedicaidGateway::RequestEligibilityDetermination.new.call(application_id: application.id)
          end
        end
      end
    end
  end
end