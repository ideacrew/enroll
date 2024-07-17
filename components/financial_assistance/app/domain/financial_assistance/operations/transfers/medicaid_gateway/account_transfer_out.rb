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

          include Dry::Monads[:result, :do, :try]
          include Acapi::Notifiers

          # add comment here
          def call(params)
            application           = yield find_application(params[:application_id])
            family                = yield find_family(application)
            payload_params        = yield construct_payload(family, application)
            payload               = yield publish(payload_params)
            _recorded             = yield record(application)
            Success(payload)
          end

          private

          def find_application(application_id)
            application = FinancialAssistance::Application.find(application_id)

            Success(application)
          rescue Mongoid::Errors::DocumentNotFound
            Failure("Unable to find Application with ID #{application_id}.")
          end

          def find_family(application)
            family = ::Family.find(application.family_id)

            Success(family)
          rescue Mongoid::Errors::DocumentNotFound
            Failure("Unable to find Family with ID #{application.family_id}.")
          end

          def construct_payload(family, application)
            result = ::Operations::Transformers::FamilyTo::Cv3Family.new.call(family)
            return result unless result.success?
            family_hash = result.value!
            app_hash = family_hash[:magi_medicaid_applications].find{ |a| a[:hbx_id] == application.hbx_id }
            family_hash[:magi_medicaid_applications] = app_hash || {}
            fam = {family: family_hash}
            Success(fam)
          end

          # publish to medicaid gateway using event source
          def publish(payload)
            FinancialAssistance::Operations::Transfers::MedicaidGateway::TransferAccount.new.call(payload)
          end

          def record(application)
            result = Try do
              application.set(account_transferred: true)
              application.set(transferred_at: DateTime.now.utc)
            end
            result.success? ? Success("recorded transfer") : Failure("could not set transfer attribute")
          end

        end
      end
    end
  end
end
