# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module FinancialAssistance
  module Operations
    module Applications
      module AptcCsrCreditEligibilities
        module Renewals
          # This Operation is used to resubmit renewal draft applications that remain in a 'renewal_draft' or 'submitted' state
          # ::FinancialAssistance::Operations::Applications::AptcCsrCreditEligibilities::Renewals::Resubmit.new.call({renewal_year: 2025})
          class Resubmit
            include Dry::Monads[:result, :do]

            # @param [Hash] opts The options to resubmit renewal_draft applications
            # @option opts [Integer] :renewal_year (required)
            # @return [Dry::Monads::Result]
            def call(params)
              validated_params      = yield validate(params)
              resubmission_results  = yield resubmit_applications(validated_params[:renewal_year])
              Success(resubmission_results)
            end

            private

            # Validates the parameters passed to the operation.
            #
            # @param params [Hash] The parameters to validate.
            # @option params [Integer] :renewal_year The renewal year.
            # @return [Success, Failure] Returns a Success object containig the params if validation passes, otherwise returns a Failure object with an error message.
            def validate(params)
              return Failure('Missing renewal_year key') unless params.key?(:renewal_year)
              return Failure("Invalid value: #{params[:renewal_year]} for key renewal_year, must be an Integer") if params[:renewal_year].nil? || !params[:renewal_year].is_a?(Integer)
              Success(params)
            end

            # Resubmits renewal applications that are in the 'renewal_draft' or 'submitted' state.
            #
            # @param renewal_eligible_apps [Array, Mongoid::Criteria] The collection of renewal eligible applications, either as an array or a Mongoid criteria.
            # @return [Success, Failure] Returns a Success object with the resubmission results if successful, otherwise returns a Failure object with an error message.
            def resubmit_applications(renewal_year)
              results = []
              applications = FinancialAssistance::Application.no_timeout.by_year(renewal_year).where(:aasm_state.in => ["submitted", "renewal_draft"])
              return Failure("No renewal eligible applications found for renewal year: #{renewal_year}") if applications.blank?

              applications.each do |application|
                resubmission_details = {
                  application_hbx_id: application.hbx_id,
                  original_state: application.aasm_state
                }
                if application.aasm_state == "submitted"
                  application.unsubmit
                  # the unsubmit method wipes out the assistance_year and effective_date, so they must be reset
                  application.update_attributes({assistance_year: renewal_year, effective_date: Date.new(renewal_year)})
                end
                result = ::FinancialAssistance::Operations::Applications::AptcCsrCreditEligibilities::Renewals::SubmitDeterminationRequest.new.call({application_id: application.id})
                resubmission_details[:resubmission_result] = result.success? ? "success" : "failure"
                resubmission_details[:result_message] = result.success? ? result.success : result.failure

                results << resubmission_details
              end
              Success(results)
            end
          end
        end
      end
    end
  end
end