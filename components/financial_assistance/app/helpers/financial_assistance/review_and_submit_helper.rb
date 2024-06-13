module FinancialAssistance
  module ReviewAndSubmitHelper
    def applicant_summary_hashes(applicant)
      def personal_info_hash(applicant)
        hash = {l10n('age') => applicant.age_of_the_applicant, l10n('gender') => applicant.gender.humanize}
        unless @all_relationships.empty?
          hash[l10n('relationship')] = applicant.relationship_kind_with_primary.humanize
        end
        hash[l10n('status')] = applicant.citizen_status.present? ? applicant.format_citizen : nil
        hash[l10n('faa.review.personal.incarcerated')] = human_boolean(applicant.is_incarcerated)
        hash[l10n('faa.review.personal.needs_coverage')] = human_boolean(applicant.is_applying_coverage)

        return {title: l10n("personal_information"), rows: hash}
      end

      def tax_info_hash(applicant)
        hash = {
          l10n('faa.tax.file_in_year', assistance_year: @application.assistance_year) => {
            value: human_boolean(applicant.is_required_to_file_taxes), 
            is_required: true
          }
        }
        if @cfl_service.displayable_field?('applicant', applicant.id, :is_joint_tax_filing)
          hash[l10n('faa.tax.filing_jointly')] = human_boolean(applicant.is_joint_tax_filing)
        end
        hash[l10n('faa.tax.dependent', assistance_year: @application.assistance_year)] = {
          value: human_boolean(applicant.is_claimed_as_tax_dependent),
          is_required: true
        }
        if @cfl_service.displayable_field?('applicant', applicant.id, :claimed_as_tax_dependent_by)
          hash[l10n('faa.tax.dependent_by')] = @application.find_applicant(applicant.claimed_as_tax_dependent_by.to_s).full_name
        end
        
        return {title: l10n("faa.review.tax_info"), edit_link: go_to_step_application_applicant_path(@application, applicant, 1), rows: hash}
      end

      def income_info_hash(applicant)
        hash = {
          strip_tags(l10n('faa.incomes.from_employer', assistance_year: assistance_year)) => {
            value: human_boolean(applicant.has_job_income),
            is_required: true
          }
        }
        if @cfl_service.displayable_field?('applicant', applicant.id, :incomes_jobs)
          applicant.incomes.jobs.each do |job|
            hash[l10n('employer_name')] = job.employer_name
            if job.employer_address.present?
              hash[l10n('employer_address_line_1')] = job.employer_address.address_1 #TODO: remove upcase when localized
              if job.employer_address.address_2.present?
                hash[l10n('employer_address_line_2')] = job.employer_address.address_2 #TODO: remove upcase when localized
              end
              hash[l10n('city')] = job.employer_address.city #TODO: remove upcase when localized
              hash[l10n('state')] = job.employer_address.state #TODO: remove upcase when localized
              hash[l10n('zip')] = job.employer_address.zip #TODO: remove upcase when localized
              if job.employer_phone.present?
                hash[l10n('employer_phone')] = format_phone(income.employer_phone.full_phone_number) #TODO: remove upcase when localized
              end
            end
          end
        end
        hash[strip_tags(l10n('faa.incomes.from_self_employment', assistance_year: assistance_year))] = {
          value: human_boolean(applicant.has_self_employment_income), 
          is_required: true
        }
        if FinancialAssistanceRegistry.feature_enabled?(:unemployment_income)
          hash[strip_tags(l10n('faa.other_incomes.unemployment', assistance_year: assistance_year))] = {
            value: human_boolean(applicant.has_unemployment_income), 
            is_required: true
          }
        end
        if EnrollRegistry.feature_enabled?(:american_indian_alaskan_native_income)
          hash[l10n('faa.other_incomes.alaska_native')] = {
            value: human_boolean(applicant.has_american_indian_alaskan_native_income), 
            is_required: true
          }
        end
        hash[strip_tags(l10n('faa.other_incomes.other_sources', assistance_year: assistance_year))] = {
          value: human_boolean(applicant.has_other_income), 
          is_required: true
        }

        return {title: l10n("faa.evidence_type_income"), edit_link: application_applicant_incomes_path(@application, applicant), rows: hash}
      end

      def deductions_info_hash(applicant)
        {
          title: l10n("faa.review.income_adjustments"),
          edit_link: application_applicant_deductions_path(@application, applicant),
          rows: {
            strip_tags(l10n('faa.deductions.income_adjustments', assistance_year: assistance_year)) => {
              value: human_boolean(applicant.has_deductions),
              is_required: true
            }
          }
        }
      end

      def coverage_info_hash(applicant)
        hash = {
          applicant_currently_enrolled => {
            value: human_boolean(applicant.has_enrolled_health_coverage),
            review_benefits_partial: ("is_enrolled" if applicant.has_enrolled_health_coverage)
          }.compact,
          applicant_eligibly_enrolled => {
            value: human_boolean(applicant.has_eligible_health_coverage),
            review_benefits_partial: ("is_eligible" if applicant.has_eligible_health_coverage)
          }.compact
        }
        if EnrollRegistry[:indian_health_service_question].feature.is_enabled && applicant.indian_tribe_member
          hash[l10n("faa.indian_health_service_eligible")] = human_boolean(applicant.health_service_eligible)
          hash[l10n("faa.indian_health_service")] = human_boolean(applicant.health_service_through_referral)
        end
        if FinancialAssistanceRegistry.feature_enabled?(:has_medicare_cubcare_eligible)
          hash[l10n("faa.medicaid_not_eligible")] = human_boolean(applicant.has_eligible_medicaid_cubcare)
          hash[l10n("faa.medicaid_cubcare_end_date")] = applicant.medicaid_cubcare_due_on.to_s.present? ? applicant.medicaid_cubcare_due_on.to_s : l10n("faa.not_applicable_abbreviation")
          hash[l10n("faa.change_eligibility_status")] = human_boolean(applicant.has_eligibility_changed)
          hash[l10n("faa.household_income_changed")] = human_boolean(applicant.has_household_income_changed)
          hash[l10n("faa.person_medicaid_last_day")] = applicant.person_coverage_end_on.to_s.present? ? applicant.person_coverage_end_on.to_s : l10n("faa.not_applicable_abbreviation")
        end
        if FinancialAssistanceRegistry[:medicaid_chip_driver_questions].enabled? && applicant.eligible_immigration_status
          hash["#{l10n("faa.medicaid_chip_ineligible")} #{TimeKeeper.date_of_record.year - 5}"] = human_boolean(applicant.medicaid_chip_ineligible)
          if applicant.medicaid_chip_ineligible
            hash[l10n("faa.immigration_status_changed")] = human_boolean(applicant.immigration_status_changed)
          end
        end
        if applicant.age_of_the_applicant < 19 && FinancialAssistanceRegistry.feature_enabled?(:has_dependent_with_coverage)
          hash[l10n("faa.has_dependent_with_coverage")] = human_boolean(applicant.has_dependent_with_coverage)
          hash[l10n("faa.dependent_job_end_on")] = applicant.dependent_job_end_on.to_s.present? ? applicant.dependent_job_end_on.to_s : l10n("faa.not_applicable_abbreviation")
        end

        # all coverage related questions are required
        hash = hash.transform_values { |value| 
          if value.is_a?(Hash)
            value[:is_required] = true
            value
          else
            {value: value, is_required: true}
          end
        }
        return {title: l10n("health_coverage"), edit_link: application_applicant_benefits_path(@application, applicant), rows: hash}
      end

      def other_questions_hash(applicant)
        hash = {}
        if applicant.is_applying_coverage
          if @cfl_service.displayable_field?('applicant', applicant.id, :is_ssn_applied)
            hash[other_questions_prompt('ssn_apply')] = human_boolean(applicant.is_ssn_applied)
          end
          if @cfl_service.displayable_field?('applicant', applicant.id, :non_ssn_apply_reason)
            hash[l10n("faa.other_ques.ssn_reason")] = applicant.non_ssn_apply_reason_readable.to_s
          end
        end
        hash[other_questions_prompt('is_pregnant')] = human_boolean(applicant.is_pregnant)
        if @cfl_service.displayable_field?('applicant', applicant.id, :pregnancy_due_on)
          hash[l10n("faa.other_ques.pregnancy_due_date")] = applicant.pregnancy_due_on.to_s
          hash[other_questions_prompt('children_expected')] = applicant.children_expected_count
        end
        if @cfl_service.displayable_field?('applicant', applicant.id, :is_post_partum_period)
          hash[other_questions_prompt(FinancialAssistanceRegistry.feature_enabled?(:post_partum_period_one_year) ? 'pregnant_last_year' : 'pregnant_last_60d')] = human_boolean(applicant.is_post_partum_period)
        end
        if @cfl_service.displayable_field?('applicant', applicant.id, :pregnancy_end_on)
          hash[l10n("faa.other_ques.pregnancy_end_date")] = applicant.pregnancy_end_on.to_s
        end
        if @cfl_service.displayable_field?('applicant', applicant.id, :is_enrolled_on_medicaid)
          hash[other_questions_prompt('is_enrolled_on_medicaid')] = human_boolean(applicant.is_enrolled_on_medicaid)
        end
        if applicant.is_applying_coverage
          if @cfl_service.displayable_field?('applicant', applicant.id, :is_former_foster_care)
            hash[other_questions_prompt('foster_care_at18')] = human_boolean(applicant.is_former_foster_care)
          end
          if @cfl_service.displayable_field?('applicant', applicant.id, :foster_care_us_state)
            hash[other_questions_prompt('foster_care_state')] = applicant.foster_care_us_state
            hash[other_questions_prompt('foster_care_age_left')] = applicant.age_left_foster_care
            hash[other_questions_prompt('foster_care_medicaid')] = human_boolean(applicant.had_medicaid_during_foster_care)
          end
          hash[other_questions_prompt('is_student')] = human_boolean(applicant.is_student)
          if @cfl_service.displayable_field?('applicant', applicant.id, :student_kind)
            hash[l10n('faa.other_ques.student_type')] = applicant.student_kind
            hash[l10n('faa.other_ques.student_status_end')] = applicant.student_status_end_on
            hash[l10n('faa.other_ques.student_school_type')] = applicant.student_school_kind
          end
          hash[other_questions_prompt('is_blind')] = human_boolean(applicant.is_self_attested_blind)
          if applicant.age_of_the_applicant >= 19 && applicant.is_applying_coverage
            if FinancialAssistanceRegistry.feature_enabled?(:primary_caregiver_other_question)
              hash[other_questions_prompt('faa.primary_caretaker_question_text')] = human_boolean(applicant.is_primary_caregiver) #TODO: fix new key per other question PR changes
            end
            if FinancialAssistanceRegistry.feature_enabled?(:primary_caregiver_relationship_other_question)
              hash[l10n('faa.review.coverage.caretaker')] = applicant.is_primary_caregiver_for&.collect{|hbx_id| @applicants_name_by_hbx_id_hash[hbx_id]}&.compact
            end
          end
          hash[other_questions_prompt('daily_living_help')] = human_boolean(applicant.has_daily_living_help)
          hash[other_questions_prompt('help_paying_bills')] = human_boolean(applicant.need_help_paying_bills)
          hash[other_questions_prompt('disability_question')] = human_boolean(applicant.is_physically_disabled)
        end

        return {title: l10n('faa.review.other_questions'), edit_link: other_questions_application_applicant_path(@application, applicant), rows: hash}
      end

      [personal_info_hash(applicant), tax_info_hash(applicant), income_info_hash(applicant), deductions_info_hash(applicant), coverage_info_hash(applicant), other_questions_hash(applicant)]
    end

    def review_benefits_esi_hash(benefit)
      hash = {l10n('hbx_profiles.employer_name') => benefit.employer_name}
      if !FinancialAssistanceRegistry.feature_enabled?(:disable_employer_address_fields)
        hash[l10n('employer_address_line_1')] = benefit.employer_address.address_1
        if benefit.employer_address.address_2.present?
          hash[l10n('employer_address_line_2')] = benefit.employer_address.address_2
        end
        hash[l10n('city')] = benefit.employer_address.city
        hash[l10n('state')] = benefit.employer_address.state
        hash[l10n('zip')] = benefit.employer_address.zip
      end

      hash[l10n('employer_phone')] = format_phone(benefit&.employer_phone&.full_phone_number)
      hash[l10n("esi_employer_ein")] = benefit.employer_id
      
      if benefit.insurance_kind == 'employer_sponsored_insurance'
        hash[l10n('faa.review.income.review_benefits_table.esi.employee_waiting_period')] = human_boolean(benefit.is_esi_waiting_period)
        hash[l10n('faa.review.income.review_benefits_table.esi.employer_minimum_standard')] = human_boolean(benefit.is_esi_mec_met)
        hash[l10n('faa.review.income.review_benefits_table.esi.covered')] = benefit.esi_covered
        hash[l10n('faa.review.income.review_benefits_table.esi.employee_minimum')] = format_benefit_cost(benefit.employee_cost, benefit.employee_cost_frequency)
        
        if display_minimum_value_standard_question?(benefit.insurance_kind)
          hash[l10n("health_plan_meets_mvs_and_affordable_question")] = human_boolean(benefit.health_plan_meets_mvs_and_affordable)
        end
      end

      if benefit.insurance_kind == 'health_reimbursement_arrangement'
        hash[l10n('faa.question.type_of_hra')] = benefit.hra_type
        hash[l10n('faa.question.max_employer_reimbursement')] = format_benefit_cost(benefit.employee_cost, benefit.employee_cost_frequency)
      end

      return hash
    end

    def family_relationships_hash
      return unless @all_relationships.present?

      hash = @all_relationships.reduce({}) do |hash, relationship|
        if member_name_by_id(relationship.applicant_id).present?
          relationship_key = l10n("faa.review.your_household.relationship", related_name: member_name_by_id(relationship.applicant_id), relationship: relationship.kind)
          hash.update(relationship_key => member_name_by_id(er.relative_id))
        end
      end

      return {title: l10n('faa.nav.family_relationships'), edit_link: financial_assistance.application_relationships_path(@application), rows: hash} unless hash.empty?
    end

    def preferences_hash
      return unless @application.years_to_renew.present? && @cfl_service.displayable_field?('application', @application.id, :years_to_renew)

      return {title: l10n('faa.review.preferences'), rows: {l10n("faa.review.preferences.eligibility_renewal") => @application.years_to_renew}}
    end

    def household_hash
      return unless @cfl_service.displayable_field?('application', @application.id, :parent_living_out_of_home_terms)

      return {title: l10n('faa.review.more_about_your_household'), rows: {l10n("faa.review.more_about_your_household.parent_living_outside") => @application.parent_living_out_of_home_terms}}
    end
  end
end