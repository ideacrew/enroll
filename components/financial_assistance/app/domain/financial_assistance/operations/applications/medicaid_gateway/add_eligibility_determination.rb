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
          include Dry::Monads[:do, :result]

          # @param [Hash] opts The options to add eligibility determination to Application(persistence object)
          # @option opts [Hash] :application_response_payload ::AcaEntities::MagiMedicaid::Application params
          # @return [Dry::Monads::Result]
          def call(params)
            application_entity = yield initialize_application_entity(params)
            application        = yield find_application(application_entity)
            application        = yield update_application(application, application_entity)
            result             = yield add_eligibility_determination(application_entity, application)
            _done              = yield cache_determination_token(application)

            Success(result)
          end

          private

          def cache_determination_token(application)
            Rails.cache.write("application_#{application.hbx_id}_determined",
                              Time.now.strftime('%Y-%m-%d %H:%M:%S.%L'),
                              expires_in: 5.minutes)

            Success('Rails cache is set for the application with timestamp.')
          end

          def initialize_application_entity(params)
            ::AcaEntities::MagiMedicaid::Operations::InitializeApplication.new.call(params)
          end

          def find_application(application_entity)
            applications = ::FinancialAssistance::Application.by_hbx_id(application_entity.hbx_id)
            if applications.count == 1
              Success(applications.first)
            else
              Failure("Found #{applications.count} applications with given hbx_id: #{application_entity.hbx_id}")
            end
          end

          def update_application(application, application_entity)
            application.assign_attributes({ has_eligibility_response: true,
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

            update_http_code_and_aasm_state(application)
            Success('Successfully updated Application object with Full Eligibility Determination')
          end

          def update_http_code_and_aasm_state(application)
            # Tie http_status_code & aasm_state update together to aviod gap b/w both the actions.
            application.assign_attributes(determination_http_status_code: 200)
            application.determine
            application.save
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
              member_determinations = ped_entity.member_determinations&.map(&:to_h)

              applicant.assign_attributes({ medicaid_household_size: ped_entity.medicaid_household_size || 0,
                                            magi_medicaid_category: ped_entity.magi_medicaid_category || 'none',
                                            magi_as_percentage_of_fpl: ped_entity.magi_as_percentage_of_fpl,
                                            magi_medicaid_monthly_income_limit: ped_entity.magi_medicaid_monthly_income_limit,
                                            magi_medicaid_monthly_household_income: ped_entity.magi_medicaid_monthly_household_income,
                                            is_without_assistance: ped_entity.is_uqhp_eligible,
                                            csr_percent_as_integer: get_csr_value(ped_entity),
                                            is_ia_eligible: ped_entity.is_ia_eligible,
                                            is_medicaid_chip_eligible: ped_entity.is_medicaid_chip_eligible || ped_entity.is_magi_medicaid,
                                            is_totally_ineligible: ped_entity.is_totally_ineligible,
                                            is_eligible_for_non_magi_reasons: ped_entity.is_eligible_for_non_magi_reasons,
                                            is_non_magi_medicaid_eligible: ped_entity.is_non_magi_medicaid_eligible})

              build_member_determinations(applicant, member_determinations) if member_determinations
              applicant.save
            end
          end

          def build_member_determinations(applicant, member_determinations)
            member_determinations&.each do |md|
              applicant.member_determinations.build(md)
            end
          end

          def update_eligibility_determination(elig_d, thh_entity)
            elig_d.assign_attributes({ effective_starting_on: thh_entity.effective_on,
                                       is_eligibility_determined: true,
                                       max_aptc: thh_entity.max_aptc.to_f,
                                       determined_at: thh_entity.determined_on,
                                       aptc_csr_annual_household_income: thh_entity.annual_tax_household_income,
                                       yearly_expected_contribution: thh_entity.yearly_expected_contribution,
                                       aptc_annual_income_limit: Money.new(0, 'USD'),
                                       csr_annual_income_limit: thh_entity.csr_annual_income_limit || Money.new(0, 'USD'),
                                       source: 'Faa' })
            elig_d.save
          end

          def get_csr_value(ped_entity)
            return 0 if ped_entity.csr.blank?
            csr = ped_entity.csr
            (csr == 'limited') ? -1 : csr.to_i
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
