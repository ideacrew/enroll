# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module FinancialAssistance
  module Operations
    module Applications
      module AptcCsrCreditEligibilities
        module Renewals
          # This class is used to trigger notice event for determined application
          class RequestDeterminationNotice
            include Dry::Monads[:result, :do, :try]
            include EventSource::Command

            def call(application_id)
              application = yield find_application(application_id)
              application_entity = yield validate(application)
              result = yield generate_determination_notice_event(application_entity)

              Success(result)
            end

            private

            def find_application(application_id)
              application = FinancialAssistance::Application.find(application_id)

              Success(application)
            rescue Mongoid::Errors::DocumentNotFound
              Failure("RequestDeterminationNotice: Unable to find Application with ID #{application_id}.")
            end

            def validate(application)
              if application.determined?
                parsed_payload = JSON.parse(application.eligibility_response_payload)
                ::AcaEntities::MagiMedicaid::Operations::InitializeApplication.new.call(parsed_payload)
              else
                Failure("RequestDeterminationNotice: Unable to send the notice for undetermined application for given application hbx_id: #{application.hbx_id}")
              end
            rescue StandardError => e
              Failure("RequestDeterminationNotice: rescued failure for the given application hbx_id: #{application.hbx_id}, error: #{e.message}")
            end

            # rubocop:disable Metrics/CyclomaticComplexity, Style/MultilineBlockChain, Metrics/PerceivedComplexity
            def generate_determination_notice_event(application_entity)
              peds = application_entity.tax_households.flat_map(&:tax_household_members).map(&:product_eligibility_determination)
              event_name =
                if peds.all?(&:is_ia_eligible)
                  :aptc_eligible
                elsif peds.all?(&:is_medicaid_chip_eligible)
                  :medicaid_chip_eligible
                elsif peds.all?(&:is_totally_ineligible)
                  :totally_ineligible
                elsif peds.all?(&:is_magi_medicaid)
                  :magi_medicaid_eligible
                elsif peds.all?(&:is_uqhp_eligible)
                  :uqhp_eligible
                else
                  :mixed_determination
                end
              event_key = "notice.determined_#{event_name}"

              params = { payload: application_entity.to_h, event_name: event_key }

              Try do
                ::FinancialAssistance::Operations::Applications::AptcCsrCreditEligibilities::Renewals::PublishRenewalRequest.new.call(params)
              end.bind do |result|
                if result.success?
                  logger.info "Successfully Published for event determination_submission_requested, with params: #{params}"
                else
                  logger.info "Failed to publish for event determination_submission_requested, with params: #{params}, failure: #{result.failure}"
                end
              end

              Success("Successfully published the payload for event: #{event_key}")
            end
            # rubocop:enable Metrics/CyclomaticComplexity, Style/MultilineBlockChain, Metrics/PerceivedComplexity
          end
        end
      end
    end
  end
end