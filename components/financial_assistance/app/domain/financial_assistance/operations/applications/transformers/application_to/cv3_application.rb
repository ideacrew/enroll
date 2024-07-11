# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
require 'aca_entities/magi_medicaid/libraries/iap_library'

module FinancialAssistance
  module Operations
    module Applications
      module Transformers
        module ApplicationTo
          # Params of an instance(persistance object) of ::FinancialAssistance::Application to be transformed.
          class Cv3Application # rubocop:disable Metrics/ClassLength
            # constructs cv3 payload for medicaid gateway.

            include Dry::Monads[:do, :result]
            include Acapi::Notifiers

            FAA_MITC_RELATIONSHIP_MAP = {
              'spouse' => :husband_or_wife,
              'domestic_partner' => :domestic_partner,
              'child' => :son_or_daughter,
              'parent' => :parent,
              'sibling' => :brother_or_sister,
              'aunt_or_uncle' => :aunt_or_uncle,
              'nephew_or_niece' => :nephew_or_niece,
              'grandchild' => :grandchild,
              'grandparent' => :grandparent,
              'parents_domestic_partner' => :parents_domestic_partner,
              'domestic_partners_child' => :domestic_partners_child,
              'father_or_mother_in_law' => :mother_in_law_or_father_in_law,
              'daughter_or_son_in_law' => :son_in_law_or_daughter_in_law,
              'brother_or_sister_in_law' => :brother_in_law_or_sister_in_law,
              'cousin' => :first_cousin
            }.freeze

            FAA_MITC_STUDENT_KINDS_MAP = {
              'Dropout' => :dropped_out,
              'Full Time' => :full_time,
              'Graduated' => :graduated,
              'Half Time' => :half_time,
              'Part Time' => :part_time,
              'Not In Schoool' => :not_in_school
            }.freeze

            FAA_MITC_STUDENT_SCHOOL_KINDS_MAP = {
              "Pre School" => :pre_school,
              "Graduate School" => :graduate_school,
              "English Language Institute" => :english_language_institute,
              "Open University" => :open_university,
              "Primary" => :primary,
              "Elementary" => :elementary,
              "GED" => :ged,
              "Junior School" => :junior_school,
              "High School" => :high_school,
              "Equivalent Vocational/Tech" => :equivalent_vocational_tech,
              "Vocational" => :vocational,
              "Technical" => :technical,
              "Undergraduate" => :undergraduate
            }.freeze

            # @param [Hash] opts The options to construct params mapping to ::AcaEntities::MagiMedicaid::Contracts::ApplicationContract
            # @option opts [::FinancialAssistance::Application] :application
            # @return [Dry::Monads::Result]
            def call(application)
              application     = yield validate(application)
              notice_options  = yield notice_options_for_app(application)
              oe_start_on     = yield fetch_oe_start_on(application)
              benchmark_premiums = yield applicant_benchmark_premium(application)
              request_payload = yield construct_payload(application, notice_options, oe_start_on, benchmark_premiums)
              Success(request_payload)
            end

            private

            def validate(application)
              return Success(application) if application.submitted? || application.is_determined?
              Failure("Application is in #{application.aasm_state} state. Please submit application.")
            end

            def notice_options_for_app(application)
              renewal_app = application.previously_renewal_draft?
              Success({ send_eligibility_notices: !renewal_app, send_open_enrollment_notices: renewal_app, paper_notification: paper_notification(application) })
            end

            def paper_notification(application)
              family = find_family(application.family_id)
              consumer_role = family.primary_person&.consumer_role

              # default to paper if we are unable to find out contact method
              return true unless consumer_role.present? && consumer_role.contact_method.present?

              consumer_role.contact_method.include?("Paper")
            end

            def fetch_oe_start_on(application)
              return Failure('Application does not have effective date') unless application.effective_date.present?
              ::Operations::Individual::OpenEnrollmentStartOn.new.call({date: application.effective_date.to_date})
            end

            def construct_payload(application, notice_options, oe_start_on, benchmark_premiums)
              payload = {family_reference: {hbx_id: find_family(application.family_id)&.hbx_assigned_id.to_s},
                         assistance_year: application.assistance_year,
                         aptc_effective_date: application.effective_date,
                         years_to_renew: application.renewal_base_year,
                         renewal_consent_through_year: application.years_to_renew,
                         is_ridp_verified: application.is_ridp_verified.present?,
                         is_renewal_authorized: application.is_renewal_authorized.present?,
                         applicants: applicants(application, benchmark_premiums),
                         relationships: application_relationships(application),
                         tax_households: tax_households(application),
                         us_state: application.us_state,
                         hbx_id: application.hbx_id,
                         oe_start_on: oe_start_on,
                         submitted_at: application.submitted_at,
                         notice_options: notice_options,
                         mitc_households: mitc_households(application),
                         mitc_tax_returns: mitc_tax_returns(application)}
              payload.merge!({full_medicaid_determination: application.full_medicaid_determination}) if FinancialAssistanceRegistry.feature_enabled?(:full_medicaid_determination_step)
              Success(payload)
            end

            def find_family(family_id)
              ::Family.find(family_id)
            end

            def encrypt(value)
              return nil unless value
              AcaEntities::Operations::Encryption::Encrypt.new.call({value: value}).value!
            end

            def applicant_qnc_code(applicant)
              return true if EnrollRegistry.feature_enabled?(:use_defaults_for_qnc_and_five_year_bar_data)
              return applicant.qualified_non_citizen if applicant.qualified_non_citizen.present?

              applicant.eligible_immigration_status ? true : false
            end

            def applicant_five_year_bar_met(applicant)
              return false if EnrollRegistry.feature_enabled?(:use_defaults_for_qnc_and_five_year_bar_data)

              applicant.five_year_bar_met.present?
            end

            def applicant_five_year_bar_applies(applicant)
              return false if EnrollRegistry.feature_enabled?(:use_defaults_for_qnc_and_five_year_bar_data)

              applicant.five_year_bar_applies.present?
            end

            # rubocop:disable Metrics/AbcSize
            # rubocop:disable Metrics/MethodLength
            def applicants(application, benchmark_premiums)
              application.applicants.inject([]) do |result, applicant|
                mitc_eligible_incomes = eligible_incomes_for_mitc(applicant)
                prior_insurance_benefit = prior_insurance(applicant)
                enrolled_benefits = enrolled_health_coverage?(applicant)
                eligible_benefits = eligible_health_coverage?(applicant)
                result << {name: name(applicant),
                           identifying_information: identifying_information(applicant),
                           demographic: demographic(applicant),
                           attestation: attestation(applicant),
                           is_primary_applicant: applicant.is_primary_applicant.present?,
                           native_american_information: native_american_information(applicant),
                           citizenship_immigration_status_information: { citizen_status: applicant.citizen_status,
                                                                         is_lawful_presence_self_attested: applicant.eligible_immigration_status.present?,
                                                                         is_resident_post_092296: applicant.is_resident_post_092296 },
                           is_consumer_role: applicant.is_consumer_role.present?,
                           is_resident_role: applicant.is_resident_role.present?,
                           is_applying_coverage: applicant.is_applying_coverage.present?,
                           five_year_bar_applies: applicant_five_year_bar_applies(applicant),
                           five_year_bar_met: applicant_five_year_bar_met(applicant),
                           qualified_non_citizen: applicant_qnc_code(applicant),
                           is_consent_applicant: applicant.is_consent_applicant.present?,
                           vlp_document: vlp_document(applicant),
                           family_member_reference: {family_member_hbx_id: applicant.person_hbx_id.to_s,
                                                     first_name: applicant.first_name,
                                                     last_name: applicant.last_name,
                                                     person_hbx_id: applicant.person_hbx_id,
                                                     is_primary_family_member: applicant.is_primary_applicant.present?},
                           person_hbx_id: applicant.person_hbx_id.to_s,
                           is_required_to_file_taxes: applicant.is_required_to_file_taxes.present?,
                           is_filing_as_head_of_household: applicant.is_filing_as_head_of_household.present?,
                           is_joint_tax_filing: applicant.is_joint_tax_filing.present?,
                           is_claimed_as_tax_dependent: applicant.is_claimed_as_tax_dependent.present?,
                           claimed_as_tax_dependent_by: applicant_reference_by_applicant_id(application, applicant.claimed_as_tax_dependent_by),
                           tax_filer_kind: applicant.tax_filer_kind,
                           student: student_information(applicant),
                           is_refugee: applicant.is_refugee.present?,
                           is_trafficking_victim: applicant.is_trafficking_victim.present?,
                           foster_care: foster(applicant),
                           pregnancy_information: pregnancy_information(applicant),
                           is_primary_caregiver: applicant.is_primary_caregiver,
                           is_subject_to_five_year_bar: applicant.is_subject_to_five_year_bar.present?,
                           is_five_year_bar_met: applicant.is_five_year_bar_met.present?,
                           is_forty_quarters: applicant.is_forty_quarters.present?,
                           is_ssn_applied: applicant.is_ssn_applied.present?,
                           non_ssn_apply_reason: applicant.non_ssn_apply_reason,
                           moved_on_or_after_welfare_reformed_law: applicant.moved_on_or_after_welfare_reformed_law.present?,
                           is_currently_enrolled_in_health_plan: applicant.is_currently_enrolled_in_health_plan.present?,
                           has_daily_living_help: applicant.has_daily_living_help.present?,
                           need_help_paying_bills: applicant.need_help_paying_bills.present?,
                           has_job_income: applicant.has_job_income.present? ? applicant.incomes.present? : false,
                           has_self_employment_income: applicant.has_self_employment_income.present? ? applicant.incomes.present? : false,
                           has_unemployment_income: applicant.has_unemployment_income.present? ? applicant.incomes.present? : false,
                           has_other_income: applicant.has_other_income.present? ? applicant.incomes.present? : false,
                           has_deductions: applicant.has_deductions.present? ? applicant.deductions.present? : false,
                           has_enrolled_health_coverage: enrolled_benefits,
                           has_eligible_health_coverage: eligible_benefits,
                           job_coverage_ended_in_past_3_months: applicant.has_dependent_with_coverage.present?,
                           job_coverage_end_date: applicant.dependent_job_end_on,
                           medicaid_and_chip: medicaid_and_chip(applicant),
                           other_health_service: {has_received: applicant.health_service_through_referral.present?,
                                                  is_eligible: applicant.health_service_eligible.present?},
                           addresses: addresses(applicant),
                           emails: emails(applicant),
                           phones: phones(applicant),
                           incomes: incomes(applicant),
                           benefits: benefits(applicant, enrolled_benefits, eligible_benefits),
                           deductions: deductions(applicant),
                           is_medicare_eligible: applicant.enrolled_or_eligible_in_any_medicare?,
                           # Does this person need help with daily life activities, such as dressing or bathing?
                           is_self_attested_long_term_care: applicant.has_daily_living_help.present?,
                           has_insurance: applicant.is_enrolled_in_insurance?,
                           has_state_health_benefit: applicant.has_state_health_benefit?,
                           had_prior_insurance: prior_insurance_benefit.present?,
                           prior_insurance_end_date: prior_insurance_benefit&.end_on,
                           age_of_applicant: applicant.age_of_the_applicant,
                           hours_worked_per_week: applicant.total_hours_worked_per_week,
                           is_temporarily_out_of_state: applicant.is_temporarily_out_of_state.present?,
                           is_claimed_as_dependent_by_non_applicant: false, # as per sb notes
                           benchmark_premium: benchmark_premiums,
                           is_homeless: applicant.is_homeless.present?,
                           mitc_income: mitc_income(applicant, mitc_eligible_incomes),
                           income_evidence: evidence_info(applicant.income_evidence),
                           esi_evidence: evidence_info(applicant.esi_evidence),
                           non_esi_evidence: evidence_info(applicant.non_esi_evidence),
                           local_mec_evidence: evidence_info(applicant.local_mec_evidence),
                           mitc_relationships: mitc_relationships(applicant),
                           mitc_is_required_to_file_taxes: applicant_is_required_to_file_taxes(applicant, mitc_eligible_incomes),
                           mitc_state_resident: mitc_state_resident(applicant, application.us_state)}
                result
              end
            end
                        # rubocop:enable Metrics/AbcSize
            # rubocop:enable Metrics/MethodLength

            def evidence_info(applicant_evidence)
              return if applicant_evidence.nil?

              {
                key: applicant_evidence.key,
                title: applicant_evidence.title,
                aasm_state: applicant_evidence.aasm_state,
                description: applicant_evidence.description,
                received_at: applicant_evidence.received_at,
                is_satisfied: applicant_evidence.is_satisfied,
                verification_outstanding: applicant_evidence.verification_outstanding,
                update_reason: applicant_evidence.update_reason,
                due_on: applicant_evidence.verif_due_date,
                external_service: applicant_evidence.external_service,
                updated_by: applicant_evidence.updated_by,
                verification_histories: applicant_evidence.verification_histories.collect { |v_his| v_his.serializable_hash.symbolize_keys },
                request_results: applicant_evidence.request_results.collect do |req_res|
                  {
                    result: req_res.result,
                    source: req_res.source,
                    source_transaction_id: req_res.source_transaction_id,
                    code: req_res.code,
                    code_description: req_res.code_description&.strftime('%F'),
                    raw_payload: req_res.raw_payload
                  }
                end
              }
            end

            def native_american_information(applicant)
              if FinancialAssistanceRegistry.feature_enabled?(:indian_alaskan_tribe_details)
                {indian_tribe_member: applicant.indian_tribe_member,
                 tribal_name: applicant.tribal_name,
                 tribal_state: applicant.tribal_state}
              else
                {indian_tribe_member: applicant.indian_tribe_member,
                 tribal_id: applicant.tribal_id}
              end
            end

            def applicant_is_required_to_file_taxes(applicant, eligible_incomes)
              return true if applicant.is_required_to_file_taxes

              total_earned_income = mitc_eligible_earned_incomes(eligible_incomes).inject(0) do |tot, inc|
                tot + inc.calculate_annual_income
              end.to_f

              total_unearned_income = mitc_eligible_unearned_incomes(eligible_incomes).inject(0) do |tot, inc|
                tot + inc.calculate_annual_income
              end.to_f

              assistance_year = applicant.application.assistance_year
              unearned_threshold_income = EnrollRegistry[:dependent_income_filing_thresholds].setting("unearned_income_filing_threshold_#{assistance_year}").item
              earned_threshold_income = EnrollRegistry[:dependent_income_filing_thresholds].setting("earned_income_filing_threshold_#{assistance_year}").item
              (total_earned_income > earned_threshold_income) || (total_unearned_income > unearned_threshold_income)
            end

            def applicant_reference_by_applicant_id(application, applicant_id)
              return nil unless applicant_id
              appli = application&.applicants&.find(applicant_id)
              return nil unless appli
              applicant_reference(appli)
            end

            def name(applicant)
              {first_name: applicant.first_name,
               middle_name: applicant.middle_name,
               last_name: applicant.last_name,
               name_sfx: applicant.name_sfx,
               name_pfx: applicant.name_pfx}
            end

            def medicaid_and_chip(applicant)
              {not_eligible_in_last_90_days: applicant.has_eligible_medicaid_cubcare.present?,
               denied_on: applicant.medicaid_cubcare_due_on,
               ended_as_change_in_eligibility: applicant.has_eligibility_changed.present?,
               hh_income_or_size_changed: applicant.has_household_income_changed.present?,
               medicaid_or_chip_coverage_end_date: applicant.person_coverage_end_on,
               ineligible_due_to_immigration_in_last_5_years: applicant.medicaid_chip_ineligible.present?,
               immigration_status_changed_since_ineligibility: applicant.immigration_status_changed.present?}
            end

            def student_information(applicant)
              { is_student: applicant.is_student.present?,
                student_kind: FAA_MITC_STUDENT_KINDS_MAP[applicant.student_kind] || applicant.student_kind,
                student_school_kind: FAA_MITC_STUDENT_SCHOOL_KINDS_MAP[applicant.student_school_kind] || applicant.student_school_kind,
                student_status_end_on: str_to_date(applicant.student_status_end_on) }
            end

            def str_to_date(student_status_end_on)
              return if student_status_end_on.blank?

              begin
                Date.strptime(student_status_end_on, '%m/%d/%Y')
              rescue StandardError
                student_status_end_on
              end
            end

            def pregnancy_information(applicant)
              {is_pregnant: applicant.is_pregnant.present?,
               is_enrolled_on_medicaid: applicant.is_enrolled_on_medicaid.present?,
               is_post_partum_period: applicant.is_post_partum_period.present?,
               expected_children_count: applicant.children_expected_count,
               pregnancy_due_on: applicant.pregnancy_due_on,
               pregnancy_end_on: applicant.pregnancy_end_on}
            end

            def foster(applicant)
              {is_former_foster_care: applicant.is_former_foster_care.present?,
               age_left_foster_care: applicant.age_left_foster_care,
               foster_care_us_state: applicant.foster_care_us_state,
               had_medicaid_during_foster_care: applicant.had_medicaid_during_foster_care.present?}
            end

            def attestation(applicant)
              {is_incarcerated: applicant.is_incarcerated.present?,
              # Enroll's UI maps to is_physically_disabled and not is_self_attested_disabled
               is_self_attested_disabled: applicant.is_physically_disabled.present?,
               is_self_attested_blind: applicant.is_self_attested_blind.present?,
               is_self_attested_long_term_care: applicant.is_self_attested_long_term_care.present?}
            end

            def identifying_information(applicant)
              has_ssn = applicant.no_ssn == "0" || applicant.ssn.present?
              {has_ssn: has_ssn, encrypted_ssn: encrypt(applicant.ssn)}
            end

            def demographic(applicant)
              {gender: applicant.gender.capitalize,
               dob: applicant.dob,
               ethnicity: applicant.ethnicity || [],
               race: applicant.race,
               is_veteran_or_active_military: applicant.is_veteran_or_active_military.present?,
               is_vets_spouse_or_child: applicant.is_vets_spouse_or_child.present?}
            end

            # All MitcIncome amounts must be expressed as annual amounts.
            def mitc_income(applicant, current_incomes)
              { amount: wages_and_salaries(current_incomes),
                taxable_interest: taxable_interest(current_incomes),
                tax_exempt_interest: 0,
                taxable_refunds: 0,
                alimony: alimony(current_incomes),
                capital_gain_or_loss: capital_gain_or_loss(current_incomes),
                pensions_and_annuities_taxable_amount: pensions_and_annuities_taxable_amount(current_incomes),
                farm_income_or_loss: farm_income_or_loss(current_incomes),
                unemployment_compensation: unemployment_compensation(current_incomes),
                other_income: other_income(current_incomes),
                magi_deductions: magi_deductions(applicant),
                adjusted_gross_income: applicant.net_annual_income.to_f || 0,
                deductible_part_of_self_employment_tax: deductible_part_of_self_employment_tax(applicant),
                ira_deduction: ira_deduction(applicant),
                student_loan_interest_deduction: student_loan_interest_deduction(applicant),
                tution_and_fees: tution_and_fees(applicant),
                other_magi_eligible_income: 0 }
            end

            def mitc_relationships(applicant)
              applicant.relationships.inject([]) do |mitc_rels, relationship|
                rela_code = find_relationship_code(relationship)
                if relationship.relative || applicant
                  mitc_rels << {
                    other_id: relationship.relative.person_hbx_id,
                    attest_primary_responsibility: applicant.is_primary_applicant.present? ? 'Y' : 'N',
                    relationship_code: rela_code
                  }
                end
                mitc_rels
              end
            end

            def find_relationship_code(relationship)
              mitc_rel = FAA_MITC_RELATIONSHIP_MAP[relationship.kind] || :other
              ::AcaEntities::MagiMedicaid::Mitc::Types::RelationshipCodeMap[mitc_rel] || '88'
            end

            # JobIncome(wages_and_salaries) & SelfEmploymentIncome(net_self_employment)
            def wages_and_salaries(current_incomes)
              ws_incomes = current_incomes.select do |inc|
                ['wages_and_salaries'].include?(inc.kind)
              end
              ws_incomes.inject(0) do |result, income|
                frequency = income.frequency_kind
                result += annual_amount(frequency(frequency), income.amount.to_i)
                result
              end
            end

            def taxable_interest(current_incomes)
              ti_incomes = current_incomes.select do |inc|
                inc.kind == 'interest'
              end
              ti_incomes.inject(0) do |result, income|
                frequency = income.frequency_kind
                result += annual_amount(frequency(frequency), income.amount.to_i)
                result
              end
            end

            def alimony(current_incomes)
              ali_incomes = current_incomes.select do |inc|
                inc.kind == 'alimony_and_maintenance'
              end
              ali_incomes.inject(0) do |result, income|
                frequency = income.frequency_kind
                result += annual_amount(frequency(frequency), income.amount.to_i)
                result
              end
            end

            def capital_gain_or_loss(current_incomes)
              cg_incomes = current_incomes.select do |inc|
                inc.kind == 'capital_gains'
              end
              cg_incomes.inject(0) do |result, income|
                frequency = income.frequency_kind
                result += annual_amount(frequency(frequency), income.amount.to_i)
                result
              end
            end

            def pensions_and_annuities_taxable_amount(current_incomes)
              pnt_incomes = current_incomes.select do |inc|
                inc.kind == 'pension_retirement_benefits'
              end
              pnt_incomes.inject(0) do |result, income|
                frequency = income.frequency_kind
                result += annual_amount(frequency(frequency), income.amount.to_i)
                result
              end
            end

            def farm_income_or_loss(current_incomes)
              fi_incomes = current_incomes.select do |inc|
                inc.kind == 'farming_and_fishing'
              end
              fi_incomes.inject(0) do |result, income|
                frequency = income.frequency_kind
                result += annual_amount(frequency(frequency), income.amount.to_i)
                result
              end
            end

            def unemployment_compensation(current_incomes)
              uc_incomes = current_incomes.select do |inc|
                inc.kind == 'unemployment_income'
              end
              uc_incomes.inject(0) do |result, income|
                frequency = income.frequency_kind
                result += annual_amount(frequency(frequency), income.amount.to_i)
                result
              end
            end

            def other_income(current_incomes)
              other_kinds = ["net_self_employment", "dividend", "rental_and_royalty", "social_security_benefit", "american_indian_and_alaskan_native",
                             "employer_funded_disability", "estate_trust", "foreign", "other", "prizes_and_awards"]
              otr_incomes = current_incomes.select do |inc|
                other_kinds.include?(inc.kind)
              end
              otr_incomes.inject(0) do |result, income|
                frequency = income.frequency_kind
                result += annual_amount(frequency(frequency), income.amount.to_i)
                result
              end
            end

            def magi_deductions(applicant)
              assistance_year_start = Date.new(applicant.application.assistance_year)
              assistance_year_end = assistance_year_start.end_of_year
              other_kinds = ["alimony_paid", "domestic_production_activities", "penalty_on_early_withdrawal_of_savings",
                             "educator_expenses", "self_employment_sep_simple_and_qualified_plans", "self_employed_health_insurance",
                             "moving_expenses", "health_savings_account", "reservists_performing_artists_and_fee_basis_government_official_expenses"]
              applicant.deductions.where(:kind.in => other_kinds).inject(0) do |result, deduction|
                frequency = deduction.frequency_kind
                deduction_end_date = calculate_end_date(deduction, assistance_year_end)
                deduction_start_date = calculate_start_date(deduction, deduction_end_date, assistance_year_start, assistance_year_end)
                return BigDecimal('0') unless (assistance_year_start..assistance_year_end).cover?(deduction_start_date)
                result += calculate_magi_deductions(deduction, deduction_start_date, deduction_end_date, assistance_year_end).to_i
                result
              end
            end

            def calculate_magi_deductions(deduction, deduction_start_date, deduction_end_date, assistance_year_end)
              end_date_year = deduction_end_date.year
              start_date_year = deduction_start_date.year
              start_day_of_year = deduction_start_date.yday
              year_difference = end_date_year - start_date_year
              days_in_start_year = Date.gregorian_leap?(deduction.start_on.year) ? 366 : 365
              end_day_of_year = deduction_end_date.yday + (year_difference * days_in_start_year)
              frequency = deduction.frequency_kind
              amount_per_day = annual_amount(frequency(frequency), deduction.amount.to_i).to_f / assistance_year_end.yday
              ((end_day_of_year - start_day_of_year + 1) * amount_per_day).round(2)
            end

            def calculate_start_date(deduction, deduction_end_date, assistance_year_start, assistance_year_end)
              if (assistance_year_start..assistance_year_end).cover?(deduction_end_date) && assistance_year_start > deduction.start_on
                assistance_year_start
              else
                deduction.start_on
              end
            end

            def calculate_end_date(deduction, assistance_year_end)
              return deduction.end_on if deduction.end_on.present? && (deduction.end_on <= assistance_year_end)
              assistance_year_end
            end

            def deductible_part_of_self_employment_tax(applicant)
              applicant.deductions.where(kind: "deductable_part_of_self_employment_taxes").inject(0) do |result, deduction|
                frequency = deduction.frequency_kind
                result += annual_amount(frequency(frequency), deduction.amount.to_i)
                result
              end
            end

            def ira_deduction(applicant)
              applicant.deductions.where(kind: "ira_deduction").inject(0) do |result, deduction|
                frequency = deduction.frequency_kind
                result += annual_amount(frequency(frequency), deduction.amount.to_i)
                result
              end
            end

            def student_loan_interest_deduction(applicant)
              applicant.deductions.where(kind: "student_loan_interest").inject(0) do |result, deduction|
                frequency = deduction.frequency_kind
                result += annual_amount(frequency(frequency), deduction.amount.to_i)
                result
              end
            end

            def tution_and_fees(applicant)
              applicant.deductions.where(kind: "tuition_and_fees").inject(0) do |result, deduction|
                frequency = deduction.frequency_kind
                result += annual_amount(frequency(frequency), deduction.amount.to_i)
                result
              end
            end

            # rubocop:disable Metrics/CyclomaticComplexity
            def annual_amount(frequency, amount)
              return 0 if frequency.blank? || amount.blank?

              case frequency
              when 'Weekly' then (amount * 52)
              when 'Monthly' then (amount * 12)
              when 'Annually' then amount
              when 'BiWeekly' then (amount * 26)
              when 'SemiMonthly' then (amount * 24)
              when 'Quarterly' then (amount * 4)
              when 'Hourly' then (amount * 8 * 5 * 52)
              when 'Daily' then (amount * 5 * 52)
              when 'SemiAnnually' then (amount * 2)
              when '13xPerYear' then (amount * 13)
              when '11xPerYear' then (amount * 11)
              when '10xPerYear' then (amount * 10)
              else 0
              end
            end
            # rubocop:enable Metrics/CyclomaticComplexity

            def monthly_amount(frequency, amount)
              annual_amount(frequency, amount) / 12
            end

            # Was the applicant receiving coverage that has expired?
            # Benefit of type is_enrolled and end dated.
            def prior_insurance(applicant)
              applicant.benefits.detect{ |b| b.is_enrolled? && b.end_on.present? }
            end

            def vlp_document(applicant)
              return if applicant.vlp_subject.nil?
              {subject: applicant.vlp_subject,
               alien_number: applicant.alien_number,
               i94_number: applicant.i94_number,
               visa_number: applicant.visa_number,
               passport_number: applicant.passport_number,
               sevis_id: applicant.sevis_id,
               naturalization_number: applicant.naturalization_number,
               receipt_number: applicant.receipt_number,
               citizenship_number: applicant.citizenship_number,
               card_number: applicant.card_number,
               country_of_citizenship: applicant.country_of_citizenship,
               expiration_date: applicant.expiration_date&.to_datetime,
               issuing_country: applicant.issuing_country,
               status: nil, # not sure what should be value here
               verification_type: nil, #not sure of value.
               comment: nil}
            end

            def addresses(applicant)
              applicant.addresses.inject([]) do |result, address|
                result << {kind: address.kind,
                           address_1: address.address_1,
                           address_2: address.address_2,
                           address_3: address.address_3,
                           city: address.city,
                           county: address.county,
                           county_fips: address.fetch_county_fips_code,
                           state: address.state,
                           zip: address.zip,
                           country_name: address.country_name}
                result
              end
            end

            def emails(applicant)
              applicant.emails.inject([]) do |result, email|
                result << {kind: email.kind,
                           address: email.address}
                result
              end
            end

            def phones(applicant)
              applicant.phones.inject([]) do |result, phone|
                result << {kind: phone.kind,
                           primary: phone.primary.present?,
                           area_code: phone.area_code,
                           number: phone.number,
                           country_code: phone.country_code,
                           extension: phone.extension,
                           full_phone_number: phone.full_phone_number}
                result
              end
            end

            def frequency(frequency)
              return nil unless frequency

              {"biweekly": "BiWeekly", "daily": "Daily", "half_yearly": "SemiAnnually",
               "monthly": "Monthly", "quarterly": "Quarterly", "weekly": "Weekly", "yearly": "Annually"}[frequency.to_sym]
            end

            def employer(instance)
              return if instance.employer_name.nil?
              {employer_name: instance.employer_name, employer_id: instance.employer_id.to_s}
            end

            def incomes(applicant)
              applicant.incomes.inject([]) do |result, income|
                result << { title: income.title,
                            kind: income.kind,
                            wage_type: income.wage_type,
                            hours_per_week: income.hours_per_week,
                            amount: income.amount.to_f,
                            amount_tax_exempt: income.amount_tax_exempt,
                            frequency_kind: frequency(income.frequency_kind),
                            start_on: income.start_on,
                            end_on: income.end_on,
                            is_projected: income.is_projected.present?,
                            tax_form: income.tax_form,
                            employer: employer(income),
                            has_property_usage_rights: income.has_property_usage_rights,
                            ssi_type: income.ssi_type,
                            submitted_at: income.submitted_at }
                result
              end
            end

            # Return false if
            #  1. the has_enrolled_health_coverage is set to false (or)
            #  2. the applicant does not have enrolled benefits
            def enrolled_health_coverage?(applicant)
              return false if applicant.has_enrolled_health_coverage.blank?

              applicant.benefits.enrolled.present?
            end

            # Return false if
            #  1. the has_eligible_health_coverage is set to false (or)
            #  2. the applicant does not have eligible benefits
            def eligible_health_coverage?(applicant)
              return false if applicant.has_eligible_health_coverage.blank?

              applicant.benefits.eligible.present?
            end

            def benefits_eligible_for_determination(applicant, enrolled_benefits, eligible_benefits)
              kinds_query = if enrolled_benefits && eligible_benefits
                              {}
                            elsif enrolled_benefits && !eligible_benefits
                              { kind: :is_enrolled }
                            elsif !enrolled_benefits && eligible_benefits
                              { kind: :is_eligible }
                            else
                              { :kind.nin => [:is_enrolled, :is_eligible] }
                            end

              applicant.benefits.where(kinds_query)
            end

            def benefits(applicant, enrolled_benefits, eligible_benefits)
              benefits_eligible_for_determination(applicant, enrolled_benefits, eligible_benefits).inject([]) do |result, benefit|
                result << { name: benefit.title,
                            kind: benefit.insurance_kind,
                            status: benefit.kind,
                            is_employer_sponsored: benefit.is_employer_sponsored.present?,
                            employer: employer(benefit),
                            esi_covered: benefit.esi_covered,
                            is_esi_waiting_period: benefit.is_esi_waiting_period.present?,
                            is_esi_mec_met: benefit.is_esi_mec_met.present?,
                            employee_cost: benefit.employee_cost,
                            employee_cost_frequency: frequency(benefit.employee_cost_frequency),
                            start_on: benefit.start_on,
                            end_on: benefit.end_on,
                            submitted_at: benefit.submitted_at,
                            health_plan_meets_mvs_and_affordable: benefit.health_plan_meets_mvs_and_affordable,
                            hra_kind: get_hra_kind(benefit.hra_type) }
                result
              end
            end

            def get_hra_kind(hra_type)
              { 'Individual coverage HRA' => :ichra, 'Qualified Small Employer HRA' => :qsehra }[hra_type]
            end

            def deductions(applicant)
              applicant.deductions.inject([]) do |result, deduction|
                result << { name: deduction.title,
                            kind: get_deduction_kind(deduction.kind),
                            amount: deduction.amount.to_f,
                            start_on: deduction.start_on,
                            end_on: deduction.end_on,
                            frequency_kind: frequency(deduction.frequency_kind),
                            submitted_at: deduction.submitted_at}
                result
              end
            end

            # Match with AcaEntities Deduction Kind
            def get_deduction_kind(deduction_kind)
              deduction_kind == 'deductable_part_of_self_employment_taxes' ? 'deductible_part_of_self_employment_taxes' : deduction_kind
            end

            def applicant_benchmark_premium(application)
              family = find_family(application.family_id) if application.family_id.present?
              return unless family.present?
              # family_member_hbx_ids = family.active_family_members.collect {|family_member| family_member.person.hbx_id}
              applicant_hbx_ids = application.applicants.pluck(:person_hbx_id)
              # return Failure("Applicants do not match family members") unless  family_member_hbx_ids.to_set == applicant_hbx_ids.to_set
              premiums = ::Operations::Products::Fetch.new.call({family: family, effective_date: application.effective_date})
              return build_zero_member_premiums(applicant_hbx_ids) if premiums.failure?

              slcsp_info = ::Operations::Products::FetchSlcsp.new.call(member_silver_product_premiums: premiums.success)
              return build_zero_member_premiums(applicant_hbx_ids) if slcsp_info.failure?

              lcsp_info = ::Operations::Products::FetchLcsp.new.call(member_silver_product_premiums: premiums.success)
              return build_zero_member_premiums(applicant_hbx_ids) if lcsp_info.failure?

              slcsp_member_premiums = applicant_hbx_ids.each_with_object([]) do |applicant_hbx_id, result|
                next applicant_hbx_id unless slcsp_info.success[applicant_hbx_id].present?

                result << slcsp_info.success[applicant_hbx_id][:health_only_slcsp_premiums]
              end.compact

              lcsp_member_premiums = applicant_hbx_ids.each_with_object([]) do |applicant_hbx_id, result|
                next applicant_hbx_id unless lcsp_info.success[applicant_hbx_id].present?

                result << lcsp_info.success[applicant_hbx_id][:health_only_lcsp_premiums]
              end.compact

              Success({ health_only_lcsp_premiums: lcsp_member_premiums, health_only_slcsp_premiums: slcsp_member_premiums })
            end

            # return zero premiums only when there is a failure monad
            def build_zero_member_premiums(applicant_hbx_ids)
              member_premiums = applicant_hbx_ids.collect do |applicant_hbx_id|
                {cost: 0.0, member_identifier: applicant_hbx_id, monthly_premium: 0.0}
              end.compact

              Success({ health_only_lcsp_premiums: member_premiums, health_only_slcsp_premiums: member_premiums })
            end

            # Physical households(mitc_households) are groups based on the member's Home Address.
            def mitc_households(application)
              address_people_combinations = [{ application.primary_applicant.home_address => [{ person_id: application.primary_applicant.person_hbx_id }] }]
              non_primary_applicants = application.applicants.where(is_primary_applicant: false)

              non_primary_applicants.each do |dependent|
                home_address = dependent.home_address
                next dependent unless home_address

                all_addresses = address_people_combinations.inject([]) do |adds, add_people_combination|
                  adds << add_people_combination.keys.first
                end

                matching_existing_address = all_addresses.compact.detect do |address|
                  address.matches_addresses?(home_address)
                end

                if matching_existing_address.present?
                  matched_combi = address_people_combinations.detect do |each_combi|
                    each_combi.keys.first.matches_addresses?(home_address) if each_combi&.keys&.first
                  end

                  address_people_combinations.delete(matched_combi)
                  matched_combi[matched_combi.keys.first] << { person_id: dependent.person_hbx_id }
                  address_people_combinations << matched_combi
                else
                  address_people_combinations << { home_address => [{ person_id: dependent.person_hbx_id }] }
                end
              end

              household_id_people_combinations = []
              address_people_combinations.each_with_index do |address_people_combination, indx|
                household_id_people_combinations << { household_id: (indx + 1).to_s, people: address_people_combination.values.first }
              end

              household_id_people_combinations
            end

            def mitc_tax_returns(application)
              application.eligibility_determinations.inject([]) do |result, ed|
                result << mitc_return(ed)
                result
              end
            end

            def mitc_return(eligibility_determination)
              ed_applicants = eligibility_determination.applicants
              non_tax_dependents = ed_applicants.where(is_claimed_as_tax_dependent: false)
              tax_dependents = ed_applicants.where(is_claimed_as_tax_dependent: true)
              person_hbx_ids = non_tax_dependents.inject([]) do |hbx_ids, applicant|
                hbx_ids << {person_id: applicant.person_hbx_id}
              end
              dependent_hbx_ids = tax_dependents.where(is_primary_applicant: false).inject([]) do |hbx_ids, applicant|
                hbx_ids << {person_id: applicant.person_hbx_id}
              end
              {filers: person_hbx_ids, dependents: dependent_hbx_ids}
            end

            def tax_households(application)
              application.eligibility_determinations.inject([]) do |result, determination|
                # TODO: get rid-off the HBX ID generate statement after testing.
                result << {hbx_id: (determination.hbx_assigned_id || FinancialAssistance::HbxIdGenerator.generate_member_id).to_s,
                           max_aptc: determination.max_aptc,
                           yearly_expected_contribution: determination.yearly_expected_contribution,
                           effective_on: determination.effective_starting_on,
                           determined_on: determination.determined_at,
                           is_insurance_assistance_eligible: insurance_assistance_eligible_for(determination),
                           annual_tax_household_income: BigDecimal((determination.aptc_csr_annual_household_income || 0).to_s),
                           tax_household_members: get_thh_member(determination, application)}
              end
            end

            def insurance_assistance_eligible_for(determination)
              if determination.is_eligibility_determined.present?
                determination.is_eligibility_determined ? 'Yes' : 'No'
              else
                'UnDetermined'
              end
            end

            def get_thh_member(eligibility, application)
              application.applicants.inject([]) do |result, app|
                next result unless app.eligibility_determination_id.to_s == eligibility.id.to_s
                result << {applicant_reference: applicant_reference(app),
                           product_eligibility_determination: {is_ia_eligible: app.is_ia_eligible?,
                                                               is_medicaid_chip_eligible: app.is_medicaid_chip_eligible,
                                                               is_totally_ineligible: app.is_totally_ineligible,
                                                               is_magi_medicaid: app.is_magi_medicaid,
                                                               is_non_magi_medicaid_eligible: app.is_non_magi_medicaid_eligible,
                                                               is_without_assistance: app.is_without_assistance,
                                                               magi_medicaid_monthly_household_income: BigDecimal((app.magi_medicaid_monthly_household_income || 0).to_s),
                                                               medicaid_household_size: app.medicaid_household_size,
                                                               magi_medicaid_monthly_income_limit: BigDecimal((app.magi_medicaid_monthly_income_limit || 0).to_s),
                                                               magi_as_percentage_of_fpl: app.magi_as_percentage_of_fpl,
                                                               magi_medicaid_category: app.magi_medicaid_category}}
                result
              end
            end

            def applicant_reference(applicant)
              {
                first_name: applicant.first_name,
                last_name: applicant.last_name,
                dob: applicant.dob,
                person_hbx_id: applicant.person_hbx_id,
                encrypted_ssn: encrypt(applicant.ssn)
              }
            end

            def application_relationships(application)
              application.relationships.inject([]) do |result, rl|
                applicant_id = rl.applicant_id
                relative_id = rl.relative_id
                next result unless applicant_id.present? || relative_id.present?
                applicant = FinancialAssistance::Applicant.find(applicant_id)
                relative = FinancialAssistance::Applicant.find(relative_id)
                next result unless applicant.present? && relative.present?
                result << {kind: rl.kind,
                           applicant_reference: applicant_reference(applicant),
                           relative_reference: applicant_reference(relative),
                           live_with_household_member: applicant.same_with_primary}
                result
              end
            end

            # Eligible month for selecting matching incomes
            def month_date_range(assistance_year, income_start_on)
              system_date = TimeKeeper.date_of_record
              if assistance_year > system_date.year
                start_of_year = Date.new(assistance_year).beginning_of_year
                start_of_year..start_of_year.end_of_month
              elsif assistance_year == system_date.year
                system_date.beginning_of_month..system_date.end_of_month
              else
                income_start_on..income_start_on.end_of_month
              end
            end

            # Incomes will be selected matching Mitc needs.
            def eligible_incomes_for_mitc(applicant)
              assistance_year = applicant.application.assistance_year
              applicant.incomes.select do |inc|
                next inc unless assistance_year
                end_on = inc.end_on || Date.new(assistance_year).end_of_year
                income_date_range = (inc.start_on)..end_on
                date_ranges_overlap?(income_date_range, month_date_range(assistance_year, inc.start_on))
              end
            end

            def date_ranges_overlap?(range_a, range_b)
              range_b.begin <= range_a.end && range_a.begin <= range_b.end
            end

            def mitc_eligible_earned_incomes(eligible_incomes)
              eligible_incomes.select { |inc| ::FinancialAssistance::Income::EARNED_INCOME_KINDS.include?(inc.kind) }
            end

            def mitc_eligible_unearned_incomes(eligible_incomes)
              eligible_incomes.select { |inc| ::FinancialAssistance::Income::UNEARNED_INCOME_KINDS.include?(inc.kind) }
            end

            def mitc_state_resident(applicant, us_state)
              home_address = applicant.home_address
              is_homeless = applicant.is_homeless
              return false if home_address.blank? && !is_homeless

              in_state_address = home_address&.state == us_state
              is_temporarily_out_of_state = applicant.is_temporarily_out_of_state

              # Should be considered Mitc state resident if 'temporarily out of state' box is NOT checked and either:
              # Case 1 - applicant has in state address
              # Case 2 - applicant does not have in state address but 'is homeless resident' box is checked
              (in_state_address && !is_temporarily_out_of_state) || (!in_state_address && !is_temporarily_out_of_state && is_homeless)
            end
          end
        end
      end
    end
  end
end
