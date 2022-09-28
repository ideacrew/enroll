# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module FinancialAssistance
  module Operations
    module Applications
      module AptcCsrCreditEligibilities
        module Renewals
          class RequestDeterminationNotice
            include Dry::Monads[:result, :do, :try]
            include EventSource::Command

            def call(application_id)
              application = find_application(application_id)
              application = validate(application)
              application = generate_determination_notice_event(application)

              Success(result)
            end

            private

            def find_application(application_id)
              application = FinancialAssistance::Application.find(application_id)

              Success(application)
            rescue Mongoid::Errors::DocumentNotFound
              Failure("Unable to find Application with ID #{application_id}.")
            end

            def validate(application)
              return Success(application) if application.determined?
              Failure("Unable to submit the application for given application hbx_id: #{application.hbx_id}, base_errors: #{application.errors.to_h}")
            end

            # scope :aptc_eligible,                 -> { where(is_ia_eligible: true) }
            # scope :medicaid_or_chip_eligible,     -> { where(is_medicaid_chip_eligible: true) }
            # scope :uqhp_eligible,                 -> { where(is_without_assistance: true) } # UQHP, is_without_assistance
            # scope :ineligible,                    -> { where(is_totally_ineligible: true) }
            # scope :eligible_for_non_magi_reasons, -> { where(is_eligible_for_non_magi_reasons: true) }



            def generate_determination_notice_event(application)
              peds = application.applicants.flat_map(&:tax_household_members).map(&:product_eligibility_determination)
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

                payload = application.eligibility_response_payload
        
              Eligibilities::PublishDetermination.new.call(payload, event_name.to_s)
        
              Success({ event: event_name, payload: mm_application })
            end


            def generate_determination_notice_event(application)


              return Success(application) if application.save
              Failure("Unable to save the application for given application hbx_id: #{application.hbx_id}, base_errors: #{application.errors.to_h}")
            rescue StandardError => e
              Failure("Submission failed for the application id: #{application.id} | backtrace: #{e}")
            end
          end
        end
      end
    end
  end
end