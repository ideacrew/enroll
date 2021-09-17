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
            application = yield find_application(params[:application_identifier])
            application = yield update_application(application)
            result = yield update_applicants(application, params)

            Success(result)
          end

          private

          def find_application(application_id)
            
            application = FinancialAssistance::Application.find(application_id)
           
            Success(application)
          rescue Mongoid::Errors::DocumentNotFound
            Failure("Unable to find Application with ID #{application_id}.")
          end

          def update_application(application)
            application.assign_attributes({ has_mec_check_response: true,
                                            mec_check_date: Date.today
                                          })
            if application.save
              Success(application)
            else
              Failure("Unable to update application with hbx_id: #{application.hbx_id}")
            end
          end

          def update_applicants(application, params)

            application.applicants.each do | applicant |
                response = params[:applicant_responses].find { |k,v| v = applicants.person_hbx_id }.value
                applicant.update_attributes!({
                    mec_check_response: response
                })

            end
            #   applicant = find_matching_applicant(elig_d, thhm_entity.applicant_reference.person_hbx_id)
            #   applicant.update_attributes!({ medicaid_household_size: ped_entity.medicaid_household_size || 0,
            #                                  magi_medicaid_category: ped_entity.magi_medicaid_category || 'none',
            #                                  magi_as_percentage_of_fpl: ped_entity.magi_as_percentage_of_fpl,
            #                                  magi_medicaid_monthly_income_limit: ped_entity.magi_medicaid_monthly_income_limit,
            #                                  magi_medicaid_monthly_household_income: ped_entity.magi_medicaid_monthly_household_income,
            #                                  is_without_assistance: ped_entity.is_uqhp_eligible,
            #                                  csr_percent_as_integer: get_csr_value(ped_entity),
            #                                  is_ia_eligible: ped_entity.is_ia_eligible,
            #                                  is_medicaid_chip_eligible: ped_entity.is_medicaid_chip_eligible || ped_entity.is_magi_medicaid,
            #                                  is_totally_ineligible: ped_entity.is_totally_ineligible,
            #                                  is_eligible_for_non_magi_reasons: ped_entity.is_eligible_for_non_magi_reasons,
            #                                  is_non_magi_medicaid_eligible: ped_entity.is_non_magi_medicaid_eligible })          
          end

          def find_matching_applicant(elig_det, applicant_ref)
            elig_det.applicants.detect do |applicant|
              applicant.person_hbx_id.to_s == applicant_ref.to_s
            end
          end
        end
      end
    end
  end
end
