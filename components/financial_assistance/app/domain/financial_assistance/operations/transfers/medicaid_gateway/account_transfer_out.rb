# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
require 'aca_entities/magi_medicaid/libraries/iap_library'

module FinancialAssistance
  module Operations
    module Transfers
      module MedicaidGateway
        # medicaid Gateway
        class AccountTransferOut
          # Sends the account transfer of application and family to the Medicaid Gateway

          include Dry::Monads[:result, :do]
          include Acapi::Notifiers

          # add comment here
          def call(application_id:)
            application           = yield find_application(application_id)
            application           = yield validate(application)
            family                = yield find_family(application)
            payload_params        = yield construct_payload(family, application)
            #transformed_payload  = yield transform_payload(payload_param)
            #validated_payload    = yield validate_payload(transformed_payload)
            payload              = yield publish(payload_params)

            Success(payload) #switch variable as methods done
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

          def find_family(application)
            family = ::Family.find(application.family_id)

            Success(family)
          rescue Mongoid::Errors::DocumentNotFound
            Failure("Unable to find Family with ID #{application.family_id}.")
          end

          def construct_payload(family, application)
            family_hash = ::Operations::Transformers::FamilyTo::Cv3Family.new.call(family).value!
            family_hash[:magi_medicaid_applications] = family_hash[:magi_medicaid_applications].select{ |a| a[:hbx_id] == application.hbx_id }
            Success(family_hash)
          end

          # def transform_payload(payload_value)
            # use ace entities to transform to json and then to atp cv3 and then to xml
          # end

          # def validate_payload(payload)
            # validate transformed against atp cv3
            # This may be built into the transforms and/or on the MG side, in which case don't need to do it twice and this can come out!
          # end

          # publish xml to medicaid gateway using event source
          def publish(payload)
            FinancialAssistance::Operations::Transfers::MedicaidGateway::TransferAccount.new.call(payload)
          end
        end
      end
    end
  end
end
