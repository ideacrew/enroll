# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
require 'aca_entities/magi_medicaid/libraries/iap_library'

module FinancialAssistance
  module Operations
    module Applications
      module Esi
        module H14
          # Requests esi mec details from h14 hub service
          class EsiMecRequest

            include Dry::Monads[:do, :result]
            include Acapi::Notifiers

            # @param [ Hash ] params Applicant Attributes
            # @return [ BenefitMarkets::Entities::Applicant ] applicant Applicant
            def call(application_id:)
              application    = yield find_application(application_id)
              payload_param  = yield construct_payload(application)
              payload_value  = yield validate_payload(payload_param)
              payload        = yield publish(payload_value, application_id)

              Success(payload)
            end

            private

            def find_application(application_id)
              application = FinancialAssistance::Application.find(application_id)

              Success(application)
            rescue Mongoid::Errors::DocumentNotFound
              Failure("Unable to find Application with ID #{application_id}.")
            end

            def construct_payload(application)
              FinancialAssistance::Operations::Applications::Transformers::ApplicationTo::Cv3Application.new.call(application)
            end

            def validate_payload(payload)
              AcaEntities::MagiMedicaid::Operations::InitializeApplication.new.call(payload)
            end

            def publish(payload, application_id)
              FinancialAssistance::Operations::Applications::Esi::H14::PublishEsiMecRequest.new.call(payload, application_id)
            end
          end
        end
      end
    end
  end
end
