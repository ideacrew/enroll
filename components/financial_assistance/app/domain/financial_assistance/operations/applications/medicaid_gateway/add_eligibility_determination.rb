# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
require 'aca_entities/magi_medicaid/libraries/iap_library'

module FinancialAssistance
  module Operations
    module Applications
      module MedicaidGateway
        # This Operation adds the eligibility determination to the Application(persistence object)
        # Operation receives the MagiMedicaidApplication with Full Determination
        class AddEligibilityDetermination
          include Dry::Monads[:result, :do]

          # @param [Hash] opts The options to add eligibility determination to Application(persistence object)
          # @option opts [Hash] :application_response_payload ::AcaEntities::MagiMedicaid::Application params
          # @return [Dry::Monads::Result]
          def call(params)
            application_entity = yield initialize_application_entity(params)
            application = yield find_application(application_entity)
            application = yield update_application(application, application_entity)
            result = yield add_eligibility_determination(application_entity, application)

            Success(result)
          end

          private

          def initialize_application_entity(params)
            ::AcaEntities::MagiMedicaid::Operations::InitializeApplication.new.call(params)
          end

          def find_application(application_entity)
            application = ::FinancialAssistance::Application.by_hbx_id(application_entity.hbx_id).first
            application.present? ? Success(application) : Failure("Could not find application with given hbx_id: #{application_entity.hbx_id}")
          end

          def update_application(application, application_entity)
            application.assign_attributes({ determination_http_status_code: 200,
                                            has_eligibility_response: true,
                                            integrated_case_id: application_entity.hbx_id,
                                            eligibility_response_payload: application_entity.to_h.to_json })
            if application.save
              Success(application)
            else
              Failure("Unable to update application with hbx_id: #{application.hbx_id}")
            end
          end

          def add_eligibility_determination(app_entity, application)
            app_entity.tax_households.each do |thh_entity|
              elig_d = find_matching_eligibility_determination(application, thh_entity)
              update_applicants(elig_d, thh_entity)
              update_eligibility_determination(elig_d, thh_entity)
            end
            application.determine!
            # Send Determination to EA
            application.send_determination_to_ea
            Success('Successfully updated Application object with Full Eligibility Determination')
          end

          def find_matching_eligibility_determination(application, thh_entity)
            application.eligibility_determinations.detect do |ed|
              ed.hbx_assigned_id.to_s == thh_entity.hbx_id.to_s
            end
          end

          def update_applicants(elig_d, thh_entity)
            thh_entity.tax_household_members.each do |thhm_entity|
              applicant = find_matching_applicant(elig_d, thhm_entity.applicant_reference.person_hbx_id)
              ped_entity = thhm_entity.product_eligibility_determination
              # TODOs:
              # 1. Does is_uqhp_eligible maps to is_without_assistance?
              #  'YES' and Done
              # 2. Does is_medicaid_chip_eligible maps to both is_medicaid_chip_eligible & is_magi_medicaid
              #    What happens for is_magi_medicaid?
              #  'YES both of them means same to EA for now' and Done
              # 3. Each member is eligible for CSR. EA currently does not support this.
              #  'New Development' - "Map Primary person's CSR to all the TaxHouseholds!" and Done
              # 4. is_eligible_for_non_magi_reasons
              applicant.update_attributes!({ medicaid_household_size: ped_entity.medicaid_household_size || 0,
                                             magi_medicaid_category: ped_entity.magi_medicaid_category || 'none',
                                             magi_as_percentage_of_fpl: ped_entity.magi_as_percentage_of_fpl,
                                             magi_medicaid_monthly_income_limit: ped_entity.magi_medicaid_monthly_income_limit,
                                             magi_medicaid_monthly_household_income: ped_entity.magi_medicaid_monthly_household_income,
                                             is_without_assistance: ped_entity.is_uqhp_eligible,
                                             is_ia_eligible: ped_entity.is_ia_eligible,
                                             is_medicaid_chip_eligible: ped_entity.is_medicaid_chip_eligible || ped_entity.is_magi_medicaid,
                                             is_totally_ineligible: ped_entity.is_totally_ineligible,
                                             is_eligible_for_non_magi_reasons: ped_entity.is_eligible_for_non_magi_reasons,
                                             is_non_magi_medicaid_eligible: ped_entity.is_non_magi_medicaid_eligible })
            end
          end

          def update_eligibility_determination(elig_d, thh_entity)
            # TODOs:
            # 1. Csr values(Done)
            # 2. Determined At(Done)
            # 3. aptc_annual_income_limit(Not needed now)
            # 4. csr_annual_income_limit(Done)
            # 5. Effective Starting On of TaxHousehold(DONE)
            elig_d.update_attributes!({ effective_starting_on: thh_entity.effective_on,
                                        is_eligibility_determined: true,
                                        max_aptc: thh_entity.max_aptc.to_f,
                                        csr_percent_as_integer: get_primary_csr_value(elig_d, thh_entity),
                                        determined_at: thh_entity.determined_on,
                                        aptc_csr_annual_household_income: thh_entity.annual_tax_household_income,
                                        aptc_annual_income_limit: 0.0,
                                        csr_annual_income_limit: thh_entity.csr_annual_income_limit,
                                        source: 'Faa' })
          end

          # Just for Demo
          def get_primary_csr_value(elig_d, thh_entity)
            primary_person_hbx_id = elig_d.application.primary_applicant.person_hbx_id
            csr = thh_entity.tax_household_members.detect do |thhm_entity|
              thhm_entity.applicant_reference.person_hbx_id == primary_person_hbx_id
            end.product_eligibility_determination.csr
            (csr == 'limited') ? 0 : csr
          rescue StandardError => _e
            0
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
