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

          include Dry::Monads[:do, :result]
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
          rescue StandardError => e
            Failure("send_successful_account_transfer_email: #{e}")
          end

          def trigger_account_transfer_notice(family)
            return unless ::EnrollRegistry.feature_enabled?(:account_transfer_notice_trigger)

            # Temporary solution to skip multiple AccountTransfer notices if primary has already received a notice
            message_subject = 'Find Out If You Qualify For Health Insurance On CoverME.gov'
            inbox = family.primary_person.inbox
            return if inbox.present? && inbox.messages.pluck(:subject).include?(message_subject)

            result = ::Operations::Notices::IvlAccountTransferNotice.new.call(family: family)
            if result.success?
              Rails.logger.info { "Triggered account transfer notice for family id: #{family.id}" }
            else
              Rails.logger.error { "Failed to trigger account transfer notice for family id: #{family.id}" }
            end
          rescue StandardError => e
            Rails.logger.error { "Failed to trigger account transfer notice for family_id #{family.id} due to error: #{e.inspect}" }
          end

          def construct_payload(application, family)
            initiated_applicants = application.applicants&.where(transfer_referral_reason: 'Initiated')&.any?
            send_successful_account_transfer_email(family) if initiated_applicants
            trigger_account_transfer_notice(family) if initiated_applicants
            response_hash = {}
            response_hash[:family_identifier] = family.hbx_assigned_id.to_s
            response_hash[:application_identifier] = application.hbx_id
            response_hash[:result] = "Success"
            Success(response_hash)
          rescue StandardError => e
            Failure("construct response payload: #{e}")
          end

        end
      end
    end
  end
end
