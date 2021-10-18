# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
require "#{Rails.root}/app/mailers/user_mailer"

module FinancialAssistance
  module Operations
    module Transfers
      module MedicaidGateway
        # Sends the result of the transfer to EA back to MG for reporting
        class AccountTransferResponse

          include Dry::Monads[:result, :do]
          include Acapi::Notifiers

          # Pass the payload from the subscriber
          # Return the result of publishing the identifiers back to MG
          def call(app_id)
            application         = yield find_application(app_id)
            family              = yield find_family(application)
            construct_payload(application, family)
          end

          private

          def find_application(app_id)
            application = FinancialAssistance::Application.find(app_id)
            Success(application)
          rescue Mongoid::Errors::DocumentNotFound
            Failure("Unable to find Application by ID.")
          end

          def find_family(application)
            family = ::Family.find(application.family_id)

            Success(family)
          rescue Mongoid::Errors::DocumentNotFound
            Failure("Unable to find Family with ID #{application.family_id}.")
          end

          def send_successful_account_transfer_email(family)
            primary_person = family.primary_person
            email_address = primary_person.emails&.first&.address
            hbx_id = primary_person&.hbx_id || ""
            UserMailer.account_transfer_success_notification(primary_person, email_address, hbx_id).deliver_now if email_address
          end

          def construct_payload(application, family)
            send_successful_account_transfer_email(family)
            response_hash = {}
            response_hash[:family_identifier] = family.hbx_assigned_id.to_s
            response_hash[:application_identifier] = application.hbx_id
            response_hash[:result] = "Success"
            Success(response_hash)
          end

        end
      end
    end
  end
end
