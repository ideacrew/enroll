# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
require 'aca_entities/magi_medicaid/libraries/iap_library'

module FinancialAssistance
  module Operations
    module Applications
      module MedicaidGateway
        # This Operation adds the MEC Check to the Application(persistence object) and Applicants
        # Operation receives the MEC Check results
        class AddMecCheck
          include Dry::Monads[:result, :do]

          # @param [Hash] opts The options to add eligibility determination to Application(persistence object)
          # @option opts [Hash] :application_response_payload ::AcaEntities::MagiMedicaid::Application params
          # @return [Dry::Monads::Result]
          def call(params)
            update_fields(params)
          end

          private

          def update_fields(params)
            payload_type = params[:type]
            case payload_type
            when "person"
              FinancialAssistance::Operations::Applications::MedicaidGateway::AddMecCheckPerson.new.call(params)
            when "application"
              FinancialAssistance::Operations::Applications::MedicaidGateway::AddMecCheckApplication.new.call(params)
            end
          end
        end
      end
    end
  end
end
