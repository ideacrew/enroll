# frozen_string_literal: true

module FinancialAssistance
  # biulds the review and submit page and the review page
  # rubocop:disable Metrics/ModuleLength
  module ReviewAndSubmitHelper
    # make sure the views are using translation keys
    module RowKeyTranslator
      def translate_row_keys(hash, map)
        hash.transform_keys do |row_key|
          map_value = send(map)[row_key]
          translation_args = map_value.is_a?(Hash) ? map_value[:translation_key] : map_value
          translation_mapper = map_value.is_a?(Hash) ? map_value[:translation_mapper] : :l10n
          method(translation_mapper).call(*translation_args)
        end
      end

      private

      def personal_info_keys
        {
          age: 'age',
          gender: 'gender',
          relationship: 'relationship',
          status: 'status',
          incarcerated: 'faa.review.personal.incarcerated',
          needs_coverage: 'faa.review.personal.needs_coverage'
        }
      end

      def tax_info_keys
        {
          file_in_year: ['faa.tax.file_in_year', {assistance_year: @application.assistance_year}],
          filing_jointly: 'faa.tax.filing_jointly',
          dependent: ['faa.tax.dependent', {assistance_year: @application.assistance_year}],
          dependent_by: 'faa.tax.dependent_by'
        }
      end

      def income_info_keys
        {
          from_employer: ['faa.incomes.from_employer', {assistance_year: assistance_year}],
          employer_name: 'employer_name',
          employer_address_line_1: 'employer_address_line_1',
          employer_address_line_2: 'employer_address_line_2',
          city: 'city',
          state: 'state',
          zip: 'zip',
          employer_phone: 'faa.incomes.employer_phone',
          from_self_employment: ['faa.incomes.from_self_employment', {assistance_year: assistance_year}],
          unemployment: ['faa.other_incomes.unemployment', {assistance_year: assistance_year}],
          alaska_native: 'faa.other_incomes.alaska_native',
          other_sources: ['faa.other_incomes.other_sources', {assistance_year: assistance_year}]
        }
      end

      def coverage_info_keys
        {
          is_enrolled: applicant_currently_enrolled_short_key,
          is_eligible: applicant_eligibly_enrolled_short_key,
          indian_health_service_eligible: 'faa.indian_health_service_eligible',
          indian_health_service: 'faa.indian_health_service',
          medicaid_not_eligible: 'faa.medicaid_not_eligible',
          medicaid_cubcare_end_date: 'faa.medicaid_cubcare_end_date',
          change_eligibility_status: 'faa.change_eligibility_status',
          household_income_changed: 'faa.household_income_changed',
          person_medicaid_last_day: 'faa.person_medicaid_last_day',
          medicaid_chip_ineligible: ['faa.medicaid_chip_ineligible', {year: TimeKeeper.date_of_record.year - 5}],
          immigration_status_changed: 'faa.immigration_status_changed',
          has_dependent_with_coverage: 'faa.has_dependent_with_coverage',
          dependent_job_end_on: 'faa.dependent_job_end_on'
        }
      end

      def other_questions_keys
        {
          ssn_apply: other_questions_prompt_translation('ssn_apply'),
          ssn_reason: 'faa.other_ques.ssn_reason',
          is_pregnant: other_questions_prompt_translation('is_pregnant'),
          pregnancy_due_date: 'faa.other_ques.pregnancy_due_date',
          children_expected: other_questions_prompt_translation('children_expected'),
          pregnant_last_year: other_questions_prompt_translation(FinancialAssistanceRegistry.feature_enabled?(:post_partum_period_one_year) ? 'pregnant_last_year' : 'pregnant_last_60d'),
          pregnancy_end_date: 'faa.other_ques.pregnancy_end_date',
          is_enrolled_on_medicaid: other_questions_prompt_translation('is_enrolled_on_medicaid'),
          foster_care_at18: other_questions_prompt_translation('foster_care_at18'),
          foster_care_state: other_questions_prompt_translation('foster_care_state'),
          foster_care_age_left: other_questions_prompt_translation('foster_care_age_left'),
          foster_care_medicaid: other_questions_prompt_translation('foster_care_medicaid'),
          is_student: other_questions_prompt_translation('is_student'),
          student_type: 'faa.other_ques.student_type',
          student_status_end: 'faa.other_ques.student_status_end',
          student_school_type: 'faa.other_ques.student_school_type',
          is_blind: other_questions_prompt_translation('is_blind'),
          primary_caretaker_question_text: other_questions_prompt_translation('primary_caretaker_question_text'),
          coverage_caretaker: 'faa.review.coverage.caretaker',
          daily_living_help: other_questions_prompt_translation('daily_living_help'),
          help_paying_bills: other_questions_prompt_translation('help_paying_bills'),
          disability_question: other_questions_prompt_translation('disability_question')
        }
      end

      def other_questions_prompt_translation(key)
        {translation_key: key, :translation_mapper => :other_questions_prompt}
      end

      def review_benefits_esi_keys
        {
          employer_name: 'hbx_profiles.employer_name',
          employer_address_line_1: 'employer_address_line_1',
          employer_address_line_2: 'employer_address_line_2',
          city: 'city',
          state: 'state',
          zip: 'zip',
          employer_phone: 'employer_phone',
          esi_employer_ein: 'esi_employer_ein',
          esi_employee_waiting_period: 'faa.review.income.review_benefits_table.esi.employee_waiting_period',
          esi_employer_minimum_standard: 'faa.review.income.review_benefits_table.esi.employer_minimum_standard',
          esi_covered: 'faa.review.income.review_benefits_table.esi.covered',
          esi_employee_minimum: 'faa.review.income.review_benefits_table.esi.employee_minimum',
          affordable_question: 'health_plan_meets_mvs_and_affordable_question',
          type_of_hra: 'faa.question.type_of_hra',
          max_employer_reimbursement: 'faa.question.max_employer_reimbursement'
        }
      end
    end

    include RowKeyTranslator

    def applicant_summary_hashes(applicant, can_edit)
      [
        personal_info_hash(applicant),
        tax_info_hash(applicant, can_edit),
        income_info_hash(applicant, can_edit),
        deductions_info_hash(applicant, can_edit),
        coverage_info_hash(applicant, can_edit),
        other_questions_hash(applicant, can_edit)
      ]
    end

    def personal_info_hash(applicant)
      hash = {age: applicant.age_of_the_applicant, gender: applicant.gender.humanize}
      hash[:relationship] = applicant.relationship_kind_with_primary.humanize
      hash[:status] = applicant.citizen_status.present? ? applicant.format_citizen : nil
      hash[:incarcerated] = human_boolean(applicant.is_incarcerated)
      hash[:needs_coverage] = human_boolean(applicant.is_applying_coverage)

      create_section_hash(title: l10n('personal_information'), rows: hash, :map => :personal_info_keys)
    end

    def income_info_hash(applicant, can_edit)
      helper = ApplicantDisplayableHelper.new(@cfl_service, applicant.id)

      hash = {from_employer: human_boolean(applicant.has_job_income)}
      hash = build_job_incomes_hash(applicant, hash) if helper.displayable?(:incomes_jobs)
      hash[:from_self_employment] = human_boolean(applicant.has_self_employment_income)
      hash[:unemployment] = human_boolean(applicant.has_unemployment_income) if FinancialAssistanceRegistry.feature_enabled?(:unemployment_income)
      hash[:alaska_native] = human_boolean(applicant.has_american_indian_alaskan_native_income) if EnrollRegistry.feature_enabled?(:american_indian_alaskan_native_income)
      hash[:other_sources] = human_boolean(applicant.has_other_income)

      create_section_hash(
        title: l10n('faa.evidence_type_income'),
        can_edit: can_edit,
        edit_link: application_applicant_incomes_path(@application, applicant),
        rows: hash,
        :map => :income_info_keys
      )
    end

    def tax_info_hash(applicant, can_edit)
      helper = ApplicantDisplayableHelper.new(@cfl_service, applicant.id)

      hash = {file_in_year: human_boolean(applicant.is_required_to_file_taxes)}
      hash[:filing_jointly] = human_boolean(applicant.is_joint_tax_filing) if helper.displayable?(:is_joint_tax_filing)
      hash[:dependent] = human_boolean(applicant.is_claimed_as_tax_dependent)
      hash[:dependent_by] = @application.find_applicant(applicant.claimed_as_tax_dependent_by.to_s).full_name if helper.displayable?(:claimed_as_tax_dependent_by)

      create_section_hash(
        title: l10n('faa.review.tax_info'),
        can_edit: can_edit,
        edit_link: go_to_step_application_applicant_path(@application, applicant, 1),
        rows: hash,
        :map => :tax_info_keys
      )
    end

    def build_job_incomes_hash(applicant, hash)
      applicant.incomes.jobs.each do |job|
        hash[:employer_name] = job.employer_name
        if job.employer_address.present?
          hash[:employer_address_line_1] = job.employer_address.address_1
          hash[:employer_address_line_2] = job.employer_address.address_2 if job.employer_address.address_2.present?
          hash[:city] = job.employer_address.city
          hash[:state] = job.employer_address.state
          hash[:zip] = job.employer_address.zip
        end
        hash[:employer_phone] = format_phone(job.employer_phone.full_phone_number) if job.employer_phone.present?
      end
      hash
    end

    def deductions_info_hash(applicant, can_edit)
      row = {l10n('faa.deductions.income_adjustments', subject: l10n('faa.other_ques.this_person'), assistance_year: assistance_year) => human_boolean(applicant.has_deductions)}
      create_section_hash(
        title: l10n('faa.review.income_adjustments'),
        can_edit: can_edit,
        edit_link: application_applicant_deductions_path(@application, applicant),
        rows: row
      )
    end

    def coverage_info_hash(applicant, can_edit)
      hash = {
        is_enrolled: {
          value: human_boolean(applicant.has_enrolled_health_coverage),
          review_benefits_partial: ('is_enrolled' if applicant.has_enrolled_health_coverage)
        }.compact,
        is_eligible: {
          value: human_boolean(applicant.has_eligible_health_coverage),
          review_benefits_partial: ('is_eligible' if applicant.has_eligible_health_coverage)
        }.compact
      }

      hash = build_ihs_questions(applicant, hash) if EnrollRegistry[:indian_health_service_question].feature.is_enabled && applicant.indian_tribe_member
      hash = build_medicaid_cubcare_questions(applicant, hash) if FinancialAssistanceRegistry.feature_enabled?(:has_medicare_cubcare_eligible)
      hash = build_chip_questions(applicant, hash) if FinancialAssistanceRegistry[:medicaid_chip_driver_questions].enabled? && applicant.eligible_immigration_status
      hash = build_dependent_coverage_questions(applicant, hash) if applicant.age_of_the_applicant < 19 && FinancialAssistanceRegistry.feature_enabled?(:has_dependent_with_coverage)

      create_section_hash(
        title: l10n('health_coverage'),
        can_edit: can_edit,
        edit_link: application_applicant_benefits_path(@application, applicant),
        rows: hash,
        :map => :coverage_info_keys
      )
    end

    def build_dependent_coverage_questions(applicant, hash)
      hash[:has_dependent_with_coverage] = human_boolean(applicant.has_dependent_with_coverage)
      hash[:dependent_job_end_on] = applicant.dependent_job_end_on.to_s.present? ? applicant.dependent_job_end_on.to_s : l10n('faa.not_applicable_abbreviation')
      hash
    end

    def build_chip_questions(applicant, hash)
      hash[:medicaid_chip_ineligible] = human_boolean(applicant.medicaid_chip_ineligible)
      hash[:immigration_status_changed] = human_boolean(applicant.immigration_status_changed) if applicant.medicaid_chip_ineligible
      hash
    end

    def build_medicaid_cubcare_questions(applicant, hash)
      hash[:medicaid_not_eligible] = human_boolean(applicant.has_eligible_medicaid_cubcare)
      hash[:medicaid_cubcare_end_date] = applicant.medicaid_cubcare_due_on.to_s.present? ? applicant.medicaid_cubcare_due_on.to_s : l10n('faa.not_applicable_abbreviation')
      hash[:change_eligibility_status] = human_boolean(applicant.has_eligibility_changed)
      hash[:household_income_changed] = human_boolean(applicant.has_household_income_changed)
      hash[:person_medicaid_last_day] = applicant.person_coverage_end_on.to_s.present? ? applicant.person_coverage_end_on.to_s : l10n('faa.not_applicable_abbreviation')
      hash
    end

    def build_ihs_questions(applicant, hash)
      hash[:indian_health_service_eligible] = human_boolean(applicant.health_service_eligible)
      hash[:indian_health_service] = human_boolean(applicant.health_service_through_referral)
      hash
    end

    def other_questions_hash(applicant, can_edit)
      helper = ApplicantDisplayableHelper.new(@cfl_service, applicant.id)

      hash = build_other_questions_hash(applicant, helper)

      create_section_hash(
        title: l10n('faa.review.other_questions'),
        can_edit: can_edit,
        edit_link: other_questions_application_applicant_path(@application, applicant),
        rows: hash,
        :map => :other_questions_keys
      )
    end

    def review_benefits_esi_hash(benefit)
      hash = {employer_name: benefit.employer_name}
      hash = add_employer_fields(hash, benefit) unless FinancialAssistanceRegistry.feature_enabled?(:disable_employer_address_fields)

      hash[:employer_phone] = format_phone(benefit&.employer_phone&.full_phone_number)
      hash[:esi_employer_ein] = benefit.employer_id

      hash = add_esi_fields(hash, benefit) if benefit.insurance_kind == 'employer_sponsored_insurance'

      if benefit.insurance_kind == 'health_reimbursement_arrangement'
        hash[:type_of_hra] = benefit.hra_type
        hash[:max_employer_reimbursement] = format_benefit_cost(benefit.employee_cost, benefit.employee_cost_frequency)
      end

      translate_row_keys(hash, :review_benefits_esi_keys)
    end

    def family_relationships_hash
      return unless @all_relationships.present?

      fr_hash = @all_relationships.reduce({}) do |hash, relationship|
        if member_name_by_id(relationship.applicant_id).present?
          relationship_key = l10n('faa.review.your_household.relationship', related_name: member_name_by_id(relationship.applicant_id), relationship: relationship.kind.titleize)
          hash.update(relationship_key => member_name_by_id(relationship.relative_id))
        end
      end

      return create_section_hash(title: l10n('faa.nav.family_relationships'), edit_link: financial_assistance.application_relationships_path(@application), rows: fr_hash) unless fr_hash.empty?
    end

    def preferences_hash
      return unless @application.years_to_renew.present? && ApplicationDisplayableHelper.new(@cfl_service, @application.id).displayable?(:years_to_renew)

      create_section_hash(title: l10n('faa.review.preferences'), rows: {l10n('faa.review.preferences.eligibility_renewal') => @application.years_to_renew})
    end

    def household_hash
      return unless ApplicationDisplayableHelper.new(@cfl_service, @application.id).displayable?(:parent_living_out_of_home_terms)

      create_section_hash(title: l10n('faa.review.more_about_your_household'), rows: {l10n('faa.review.more_about_your_household.parent_living_outside') => human_boolean(@application.parent_living_out_of_home_terms)})
    end

    def build_other_questions_hash(applicant, helper)
      hash = {}
      if applicant.is_applying_coverage
        hash[:ssn_apply] = human_boolean(applicant.is_ssn_applied) if helper.displayable?(:is_ssn_applied)
        hash[:ssn_reason] = applicant.non_ssn_apply_reason_readable.to_s if helper.displayable?(:non_ssn_apply_reason)
      end

      hash[:is_pregnant] = human_boolean(applicant.is_pregnant)
      if helper.displayable?(:pregnancy_due_on)
        hash[:pregnancy_due_date] = applicant.pregnancy_due_on.to_s
        hash[:children_expected] = applicant.children_expected_count
      end
      hash[:pregnant_last_year] = human_boolean(applicant.is_post_partum_period) if helper.displayable?(:is_post_partum_period)
      hash[:pregnancy_end_date] = applicant.pregnancy_end_on.to_s if helper.displayable?(:pregnancy_end_on)
      hash[:is_enrolled_on_medicaid] = human_boolean(applicant.is_enrolled_on_medicaid) if helper.displayable?(:is_enrolled_on_medicaid)

      return hash unless applicant.is_applying_coverage

      build_applying_coverage_other_questions_hash(applicant, hash, helper)
    end

    def build_applying_coverage_other_questions_hash(applicant, hash, helper)
      hash[:foster_care_at18] = human_boolean(applicant.is_former_foster_care) if helper.displayable?(:is_former_foster_care)
      hash = build_foster_care_questions(hash, applicant) if helper.displayable?(:foster_care_us_state)
      hash[:is_student] = human_boolean(applicant.is_student)
      hash = build_student_kind_questions(hash, applicant) if helper.displayable?(:student_kind)
      hash[:is_blind] = human_boolean(applicant.is_self_attested_blind)
      hash = build_caregiver_questions(hash, applicant) if applicant.age_of_the_applicant >= 19 && applicant.is_applying_coverage
      hash[:daily_living_help] = human_boolean(applicant.has_daily_living_help)
      hash[:help_paying_bills] = human_boolean(applicant.need_help_paying_bills)
      hash[:disability_question] = human_boolean(applicant.is_physically_disabled)
      hash
    end

    def build_caregiver_questions(hash, applicant)
      hash[:primary_caretaker_question_text] = human_boolean(applicant.is_primary_caregiver) if FinancialAssistanceRegistry.feature_enabled?(:primary_caregiver_other_question)
      hash[:coverage_caretaker] = applicant.is_primary_caregiver_for&.collect{|hbx_id| @applicants_name_by_hbx_id_hash[hbx_id]}&.compact if FinancialAssistanceRegistry.feature_enabled?(:primary_caregiver_relationship_other_question)
      hash
    end

    def build_student_kind_questions(hash, applicant)
      hash[:student_type] = applicant.student_kind
      hash[:student_status_end] = applicant.student_status_end_on
      hash[:student_school_type] = applicant.student_school_kind
      hash
    end

    def build_foster_care_questions(hash, applicant)
      hash[:foster_care_state] = applicant.foster_care_us_state
      hash[:foster_care_age_left] = applicant.age_left_foster_care
      hash[:foster_care_medicaid] = human_boolean(applicant.had_medicaid_during_foster_care)
      hash
    end

    def add_employer_fields(hash, benefit)
      hash[:employer_address_line_1] = benefit.employer_address.address_1
      hash[:employer_address_line_2] = benefit.employer_address.address_2 if benefit.employer_address.address_2.present?
      hash[:city] = benefit.employer_address.city
      hash[:state] = benefit.employer_address.state
      hash[:zip] = benefit.employer_address.zip
      hash
    end

    def add_esi_fields(hash, benefit)
      hash[:esi_employee_waiting_period] = human_boolean(benefit.is_esi_waiting_period)
      hash[:esi_employer_minimum_standard] = human_boolean(benefit.is_esi_mec_met)
      hash[:esi_covered] = benefit.esi_covered
      hash[:esi_employee_minimum] = format_benefit_cost(benefit.employee_cost, benefit.employee_cost_frequency)
      hash[:affordable_question] = human_boolean(benefit.health_plan_meets_mvs_and_affordable) if display_minimum_value_standard_question?(benefit.insurance_kind)
    end

    private

    # displayable field helpers
    class DisplayableHelper
      def initialize(service, id)
        @service = service
        @id = id
      end

      def displayable?(attribute)
        @service.displayable_field?(@class.name.demodulize.downcase, @id, attribute)
      end
    end

    # display helper for applicant
    class ApplicantDisplayableHelper < DisplayableHelper
      def initialize(service, id)
        @class = FinancialAssistance::Applicant
        super
      end
    end

    # display helper for application
    class ApplicationDisplayableHelper < DisplayableHelper
      def initialize(service, id)
        @class = FinancialAssistance::Application
        super
      end
    end

    def create_section_hash(title:, rows:, can_edit: true, edit_link: nil, map: nil)
      {title: title, edit_link: can_edit ? edit_link : nil, rows: map.nil? ? rows : translate_row_keys(rows, map)}
    end
  end
  # rubocop:enable Metrics/ModuleLength
end
