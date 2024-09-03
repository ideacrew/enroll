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
              renewal_eligible_apps = yield applications_for_families(validated_params)
              resubmission_results  = yield resubmit_applications(renewal_eligible_apps)
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

            # Fetches the current year applications that are eligible for renewal in the given renewal year.
            # The current year is assumed to be the year before the given renewal year.
            #
            # @param params [Hash] The parameters to filter applications.
            # @option params [Integer] :renewal_year The renewal year to filter applications.
            # @return [Success, Failure] Returns a Success object with eligible applications if found, otherwise returns a Failure object with an error message.
            def applications_for_families(params)
              @renewal_year = params[:renewal_year]
              @current_plan_year = @renewal_year.pred
              family_ids = ::HbxEnrollment.individual_market.enrolled.current_year.distinct(:family_id)
              latest_applications = ::FinancialAssistance::Application.collection.aggregate([
                {
                  '$match': {
                    'assistance_year': @current_plan_year,
                    'aasm_state': 'determined',
                    'family_id': { '$in': family_ids }
                  }
                },
                {
                  '$sort': {
                    'family_id': 1,
                    'created_at': -1
                  }
                },
                {
                  '$group': {
                    '_id': '$family_id',
                    'latest_application_id': { '$first': '$_id' }
                  }
                }
              ])

              latest_application_ids = latest_applications.map { |doc| doc['latest_application_id'] }
              eligible_applications = if FinancialAssistanceRegistry.feature_enabled?(:skip_eligibility_redetermination)
                                        # when the skip_eligibility_redetermination feature is enabled, the eligible_for_renewal? method must be checked on each application as it may return true or false
                                        ::FinancialAssistance::Application.no_timeout.where(:_id.in => latest_application_ids).select(&:eligible_for_renewal?)
                                      else
                                        # when the feature is disabled, the eligible_for_renewal? method always returns true and the eligible applications can be fetched directly
                                        ::FinancialAssistance::Application.where(:_id.in => latest_application_ids)
                                      end

              eligible_applications.present? ? Success(eligible_applications) : Failure("No renewal eligible applications found for renewal year: #{@renewal_year}")
            end

            # Resubmits renewal applications that are in the 'renewal_draft' or 'submitted' state.
            #
            # @param renewal_eligible_apps [Array, Mongoid::Criteria] The collection of renewal eligible applications, either as an array or a Mongoid criteria.
            # @return [Success, Failure] Returns a Success object with the resubmission results if successful, otherwise returns a Failure object with an error message.
            def resubmit_applications(renewal_eligible_apps)
              renewal_eligible_family_ids = if renewal_eligible_apps.is_a?(Array)
                                              renewal_eligible_apps.map(&:family_id).uniq
                                            else
                                              renewal_eligible_apps.distinct(:family_id)
                                            end
              results = []
              FinancialAssistance::Application.no_timeout.by_year(@renewal_year).where(:family_id.in => renewal_eligible_family_ids, :aasm_state.in => ["submitted", "renewal_draft"]).each do |application|
                resubmission_details = {
                  application_hbx_id: application.hbx_id,
                  original_state: application.aasm_state
                }
                if application.aasm_state == "submitted"
                  application.unsubmit
                  # the unsubmit method wipes out the assistance_year and effective_date, so they must be reset
                  application.update_attributes({assistance_year: @renewal_year, effective_date: Date.new(@renewal_year)})
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