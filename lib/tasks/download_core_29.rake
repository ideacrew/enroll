namespace :migrations do
  desc "download core 29"
  task :download_core_29 => :environment do
    desc "Load the people data"
    seedfile_applications = File.open('db/applications_load.rb', 'a')
    seedfile_applicants = File.open('db/applicants_load.rb', 'a')
    field_names=%w{id first_name last_name }
    Dir.mkdir("hbx_report") unless File.exists?("hbx_report")
    file_name = "#{Rails.root}/hbx_report/families_with_application.csv"
    file_name_applicants = "#{Rails.root}/hbx_report/families_with_applicants.csv"
    file = File.read('db/person.json')
    data_hash = JSON.parse(file)

    application_field_names = %w(
                    family_id
                    integrated_case_id
                    haven_app_id
                    haven_ic_id
                    e_case_id
                    applicant_kind
                    request_kind
                    motivation_kind
                    is_joint_tax_filing
                    eligibility_determination_id
                    aasm_state
                    submitted_at
                    effective_date
                    timeout_response_last_submitted_at
                    assistance_year
                    is_renewal_authorized
                    renewal_base_year
                    is_requesting_voter_registration_application_in_mail
                    us_state
                    medicaid_terms
                    medicaid_insurance_collection_terms
                    report_change_terms
                    parent_living_out_of_home_terms
                    attestation_terms
                    submission_terms
                    request_full_determination
                    is_ridp_verified
                    renewal_base_year
                    years_to_renew
                    )

    applicants_field_names = %w(
                      assisted_income_validation
                      assisted_mec_validation
                      assisted_income_reason
                      assisted_mec_reason
                      aasm_state
                      family_member_id
                      is_active
                      has_fixed_address
                      is_living_in_state
                      is_temp_out_of_state
                      is_required_to_file_taxes
                      tax_filer_kind
                      is_joint_tax_filing
                      is_claimed_as_tax_dependent
                      claimed_as_tax_dependent_by
                      is_ia_eligible
                      is_medicaid_chip_eligible
                      is_non_magi_medicaid_eligible
                      is_totally_ineligible
                      is_without_assistance
                      has_income_verification_response
                      has_mec_verification_response
                      magi_medicaid_monthly_household_income
                      magi_medicaid_monthly_income_limit
                      magi_as_percentage_of_fpl
                      magi_medicaid_type
                      magi_medicaid_category
                      medicaid_household_size
                      is_magi_medicaid
                      is_medicare_eligible
                      is_student
                      student_kind
                      student_school_kind
                      student_status_end_on
                      is_self_attested_blind
                      is_self_attested_disabled
                      is_self_attested_long_term_care
                      is_veteran
                      is_refugee
                      is_trafficking_victim
                      is_former_foster_care
                      age_left_foster_care
                      foster_care_us_state
                      had_medicaid_during_foster_care
                      is_pregnant
                      is_enrolled_on_medicaid
                      is_post_partum_period
                      children_expected_count
                      pregnancy_due_on
                      pregnancy_end_on
                      is_subject_to_five_year_bar
                      is_five_year_bar_met
                      is_forty_quarters
                      is_ssn_applied
                      non_ssn_apply_reason
                      moved_on_or_after_welfare_reformed_law
                      is_veteran_or_active_military
                      is_spouse_or_dep_child_of_veteran_or_active_military
                      is_currently_enrolled_in_health_plan
                      has_daily_living_help
                      need_help_paying_bills
                      is_resident_post_092296
                      is_vets_spouse_or_child
                      has_job_income
                      has_self_employment_income
                      has_other_income
                      has_deductions
                      has_enrolled_health_coverage
                      has_eligible_health_coverage
                      )

    CSV.open(file_name, "wb") do |csv|
      csv << application_field_names
      data_hash['person'].each do |p|
        first_name = p["first_name"]
        last_name = p["last_name"]
        person = Person.where(first_name: first_name).and(last_name: last_name)
        family = person.first.primary_family
        family_id = family.id
        latest_submitted_application = Family.find(family_id).latest_submitted_application
        application_in_progress = Family.find(family_id).application_in_progress
        applicants = latest_submitted_application.applicants

        csv << [
            family_id,
            latest_submitted_application.integrated_case_id.nil? ? "nil" : latest_submitted_application.integrated_case_id,
            latest_submitted_application.haven_app_id.nil? ? "nil" : latest_submitted_application.haven_app_id,
            latest_submitted_application.haven_ic_id.nil? ? "nil" : latest_submitted_application.haven_ic_id,
            latest_submitted_application.e_case_id.nil? ? "nil" : latest_submitted_application.e_case_id,
            latest_submitted_application.applicant_kind.nil? ? "nil" : latest_submitted_application.applicant_kind,
            latest_submitted_application.request_kind.nil? ? "nil" : latest_submitted_application.request_kind,
            latest_submitted_application.motivation_kind.nil? ? "nil" : latest_submitted_application.motivation_kind,
            latest_submitted_application.is_joint_tax_filing.nil? ? "nil" : latest_submitted_application.is_joint_tax_filing,
            latest_submitted_application.eligibility_determination_id.nil? ? "nil" : latest_submitted_application.eligibility_determination_id,
            latest_submitted_application.aasm_state.nil? ? "nil" : latest_submitted_application.aasm_state,
            latest_submitted_application.submitted_at.nil? ? "nil" : latest_submitted_application.submitted_at,
            latest_submitted_application.effective_date.nil? ? "nil" : latest_submitted_application.effective_date,
            latest_submitted_application.timeout_response_last_submitted_at.nil? ? "nil" : latest_submitted_application.timeout_response_last_submitted_at,
            latest_submitted_application.assistance_year.nil? ? "nil" : latest_submitted_application.assistance_year,
            latest_submitted_application.is_renewal_authorized.nil? ? "nil" : latest_submitted_application.is_renewal_authorized,
            latest_submitted_application.renewal_base_year.nil? ? "nil" : latest_submitted_application.renewal_base_year,
            latest_submitted_application.is_requesting_voter_registration_application_in_mail.nil? ? "nil" : latest_submitted_application.is_requesting_voter_registration_application_in_mail,
            latest_submitted_application.us_state.nil? ? "nil" : latest_submitted_application.us_state,
            latest_submitted_application.medicaid_terms.nil? ? "nil" : latest_submitted_application.medicaid_terms,
            latest_submitted_application.medicaid_insurance_collection_terms.nil? ? "nil" : latest_submitted_application.medicaid_insurance_collection_terms,
            latest_submitted_application.report_change_terms.nil? ? "nil" : latest_submitted_application.report_change_terms,
            latest_submitted_application.parent_living_out_of_home_terms.nil? ? "nil" : latest_submitted_application.parent_living_out_of_home_terms,
            latest_submitted_application.attestation_terms.nil? ? "nil" : latest_submitted_application.attestation_terms,
            latest_submitted_application.submission_terms.nil? ? "nil" : latest_submitted_application.submission_terms,
            latest_submitted_application.request_full_determination.nil? ? "nil" : latest_submitted_application.request_full_determination,
            latest_submitted_application.is_ridp_verified.nil? ? "nil" : latest_submitted_application.is_ridp_verified,
            latest_submitted_application.renewal_base_year,
            latest_submitted_application.years_to_renew
        ]

        CSV.open(file_name_applicants, "wb") do |csv|
          csv << applicants_field_names
          applicants.each do |a|
            csv << [
                    a.assisted_income_validation.nil? ? "nil" : a.assisted_income_validation,
                    a.assisted_mec_validation.nil? ? "nil" : a.assisted_mec_validation,
                    a.assisted_income_reason.nil? ? "nil" : a.assisted_income_reason,
                    a.assisted_mec_reason.nil? ? "nil" : a.assisted_mec_reason,
                    a.aasm_state.nil? ? "nil" : a.aasm_state,
                    a.family_member_id.nil? ? "nil" : a.family_member_id,
                    a.is_active.nil? ? "nil" : a.is_active,
                    a.has_fixed_address.nil? ? "nil" : a.has_fixed_address,
                    a.is_living_in_state.nil? ? "nil" : a.is_living_in_state,
                    a.is_temp_out_of_state.nil? ? "nil" : a.is_temp_out_of_state,
                    a.is_required_to_file_taxes.nil? ? "nil" : a.is_required_to_file_taxes,
                    a.tax_filer_kind.nil? ? "nil" : a.tax_filer_kind,
                    a.is_joint_tax_filing.nil? ? "nil" : a.is_joint_tax_filing,
                    a.is_claimed_as_tax_dependent.nil? ? "nil" : a.is_claimed_as_tax_dependent,
                    a.claimed_as_tax_dependent_by.nil? ? "nil" : a.claimed_as_tax_dependent_by,
                    a.is_ia_eligible.nil? ? "nil" : a.is_ia_eligible,
                    a.is_medicaid_chip_eligible.nil? ? "nil" : a.is_medicaid_chip_eligible,
                    a.is_non_magi_medicaid_eligible.nil? ? "nil" : a.is_non_magi_medicaid_eligible,
                    a.is_totally_ineligible.nil? ? "nil" : a.is_totally_ineligible,
                    a.is_without_assistance.nil? ? "nil" : a.is_without_assistance,
                    a.has_income_verification_response.nil? ? "nil" : a.has_income_verification_response,
                    a.has_mec_verification_response.nil? ? "nil" : a.has_mec_verification_response,
                    a.magi_medicaid_monthly_household_income.nil? ? "nil" : a.magi_medicaid_monthly_household_income,
                    a.magi_medicaid_monthly_income_limit.nil? ? "nil" : a.magi_medicaid_monthly_income_limit,
                    a.magi_as_percentage_of_fpl.nil? ? "nil" : a.magi_as_percentage_of_fpl,
                    a.magi_medicaid_type.nil? ? "nil" : a.magi_medicaid_type,
                    a.magi_medicaid_category.nil? ? "nil" : a.magi_medicaid_category,
                    a.medicaid_household_size.nil? ? "nil" : a.medicaid_household_size,
                    a.is_magi_medicaid.nil? ? "nil" : a.is_magi_medicaid,
                    a.is_medicare_eligible.nil? ? "nil" : a.is_medicare_eligible,
                    a.is_student.nil? ? "nil" : a.is_student,
                    a.student_kind.nil? ? "nil" : a.student_kind,
                    a.student_school_kind.nil? ? "nil" : a.student_school_kind,
                    a.student_status_end_on.nil? ? "nil" : a.student_status_end_on,
                    a.is_self_attested_blind.nil? ? "nil" : a.is_self_attested_blind,
                    a.is_self_attested_disabled.nil? ? "nil" : a.is_self_attested_disabled,
                    a.is_self_attested_long_term_care.nil? ? "nil" : a.is_self_attested_long_term_care,
                    a.is_veteran.nil? ? "nil" : a.is_veteran,
                    a.is_refugee.nil? ? "nil" : a.is_refugee,
                    a.is_trafficking_victim.nil? ? "nil" : a.is_trafficking_victim,
                    a.is_former_foster_care.nil? ? "nil" : a.is_former_foster_care,
                    a.age_left_foster_care.nil? ? "nil" : a.age_left_foster_care,
                    a.foster_care_us_state.nil? ? "nil" : a.foster_care_us_state,
                    a.had_medicaid_during_foster_care.nil? ? "nil" : a.had_medicaid_during_foster_care,
                    a.is_pregnant.nil? ? "nil" : a.is_pregnant,
                    a.is_enrolled_on_medicaid.nil? ? "nil" : a.is_enrolled_on_medicaid,
                    a.is_post_partum_period.nil? ? "nil" : a.is_post_partum_period,
                    a.children_expected_count.nil? ? "nil" : a.children_expected_count,
                    a.pregnancy_due_on.nil? ? "nil" : a.pregnancy_due_on,
                    a.pregnancy_end_on.nil? ? "nil" : a.pregnancy_end_on,
                    a.is_subject_to_five_year_bar.nil? ? "nil" : a.is_subject_to_five_year_bar,
                    a.is_five_year_bar_met.nil? ? "nil" : a.is_five_year_bar_met,
                    a.is_forty_quarters.nil? ? "nil" : a.is_forty_quarters,
                    a.is_ssn_applied.nil? ? "nil" : a.is_ssn_applied,
                    a.non_ssn_apply_reason.nil? ? "nil" : a.non_ssn_apply_reason,
                    a.moved_on_or_after_welfare_reformed_law.nil? ? "nil" : a.moved_on_or_after_welfare_reformed_law,
                    a.is_veteran_or_active_military.nil? ? "nil" : a.is_veteran_or_active_military,
                    a.is_spouse_or_dep_child_of_veteran_or_active_military.nil? ? "nil" : a.is_spouse_or_dep_child_of_veteran_or_active_military,
                    a.is_currently_enrolled_in_health_plan.nil? ? "nil" : a.is_currently_enrolled_in_health_plan,
                    a.has_daily_living_help.nil? ? "nil" : a.has_daily_living_help,
                    a.need_help_paying_bills.nil? ? "nil" : a.need_help_paying_bills,
                    a.is_resident_post_092296.nil? ? "nil" : a.is_resident_post_092296,
                    a.is_vets_spouse_or_child.nil? ? "nil" : a.is_vets_spouse_or_child,
                    a.has_job_income.nil? ? "nil" : a.has_job_income,
                    a.has_self_employment_income.nil? ? "nil" : a.has_self_employment_income,
                    a.has_other_income.nil? ? "nil" : a.has_other_income,
                    a.has_deductions.nil? ? "nil" : a.has_deductions,
                    a.has_enrolled_health_coverage.nil? ? "nil" : a.has_enrolled_health_coverage,
                    a.has_eligible_health_coverage.nil? ? "nil" : a.has_eligible_health_coverage]
          end
        end
      end
    end
    puts "loaded to CSV"
  end
end
