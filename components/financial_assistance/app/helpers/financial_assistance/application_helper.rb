# frozen_string_literal: true

module FinancialAssistance
  module ApplicationHelper

    def to_est(datetime)
      datetime.in_time_zone("Eastern Time (US & Canada)") if datetime.present?
    end

    def total_aptc_across_eligibility_determinations(application_id)
      eds = FinancialAssistance::Application.find(application_id).eligibility_determinations
      eds.map(&:max_aptc).flat_map(&:to_f).inject(:+)
    end
    def eligible_applicants(application_id, eligibility_flag)
      application = FinancialAssistance::Application.find(application_id)
      full_names = application.active_applicants.where(eligibility_flag => true).map(&:full_name)
      # capitalize each name of full name individually, as titleize will cause spacing issues if multiple capital letters already in applicant name
      full_names.map{ |full_name| capitalize_full_name(full_name) }
    end
    def any_csr_ineligible_applicants?(application_id)
      application = FinancialAssistance::Application.find(application_id)
      application.eligibility_determinations.inject([]) do |csr_eligible, ed_obj|
        csr_eligible << ed_obj.csr_percent_as_integer
        csr_eligible
      end.include?(0)
    end

    def csr_73_87_or_94_eligible_applicants?(application_id)
      application = FinancialAssistance::Application.find(application_id)
      full_names = application.applicants.select(&:is_csr_73_87_or_94?).map(&:full_name)
      full_names.map{ |full_name| capitalize_full_name(full_name) }
    end

    def csr_100_eligible_applicants?(application_id)
      application = FinancialAssistance::Application.find(application_id)
      full_names = application.applicants.select(&:is_csr_100?).map(&:full_name)
      full_names.map{ |full_name| capitalize_full_name(full_name) }
    end

    def csr_limited_eligible_applicants?(application_id)
      application = FinancialAssistance::Application.find(application_id)
      full_names = application.applicants.select(&:is_csr_limited?).map(&:full_name)
      full_names.map{ |full_name| capitalize_full_name(full_name) }
    end

    def applicant_age(applicant)
      now = Time.now.utc.to_date
      dob = applicant.dob
      now.year - dob.year - (now.month > dob.month || (now.month == dob.month && now.day >= dob.day) ? 0 : 1)
    end

    def find_next_application_path(application)
      if application.incomplete_applicants?
        go_to_step_application_applicant_path application, application.next_incomplete_applicant, 1
      else
        review_and_submit_application_path application
      end
    end

    def find_previous_from_step_one
      model_name = @model.class.to_s.split('::').last.downcase
      if  model_name == "applicant"
        edit_application_path(@application)
      elsif model_name == "application"
        review_and_submit_application_path(@application)
      else
        send("application_applicant_#{model_name.pluralize}_path", @application, @applicant)
      end
    end

    def find_applicant_path(application, applicant, options = {})
      document_flow = ['incomes', 'deductions', 'benefits']
      next_path = document_flow.find do |embeded_document|
        # this is a complicated condition but we need to make sure we don't work backwards in the flow from incomes to deductions to benefits
        # so if a current option is passed in we won't consider anything before it
        # if a current option is not passed then .index will return nil
        # and instead we'll short circuit by checking that -1 is less then i, which always would be true
        ((document_flow.index(options[:current]) || -1) < document_flow.index(embeded_document)) && applicant.send(embeded_document).present?
      end
      next_path ? send("application_applicant_#{next_path}_path", application, applicant) : other_questions_application_applicant_path(application, applicant)
    end

    def find_previous_applicant_path(application, applicant, options = {})
      reverse_document_flow = ['benefits', 'deductions', 'incomes']
      previous_path = reverse_document_flow.find do |embeded_document|
        # this is a complicated condition but we need to make sure we don't work backwards in the flow from incomes to deductions to benefits
        # so if a current option is passed in we won't consider anything before it
        # if a current option is not passed then .index will return nil
        # and instead we'll short circuit by checking that -1 is less then i, which always would be true
        ((reverse_document_flow.index(options[:current]) || -1) < reverse_document_flow.index(embeded_document)) && applicant.send(embeded_document).present?
      end
      previous_path ? send("application_applicant_#{previous_path}_path", application, applicant) : go_to_step_application_applicant_path(application, applicant, 2)
    end

    def left_nav_css(conditional)
      'cna disabled' unless conditional
    end

    def show_faa_status
      return true if controller_name == 'applications' && action_name == 'edit'
      false
    end

    def claim_eligible_tax_dependents
      return if @application.blank? || @applicant.blank?
      @application.active_applicants.where(is_claimed_as_tax_dependent: false).map! do |applicant|
        [applicant.full_name, applicant.id.to_s] if applicant != @applicant && applicant.is_required_to_file_taxes? && applicant.claimed_as_tax_dependent_by != @applicant.id
      end
    end

    def frequency_kind_options
      { 'Bi Weekly' => 'biweekly', 'Daily' => 'daily', 'Half Yearly' => 'half_yearly', 'Monthly' => 'monthly',  'Quarterly' => 'quarterly', 'Weekly' => 'weekly', 'Yearly' => 'yearly' }
    end

    def state_options
      %w[AL AK AZ AR CA CO CT DE DC FL GA HI ID IL IN IA KS KY LA ME MD MA MI MN MS MO MT NE NV NH NJ NM NY NC ND OH OK OR PA PR RI SC SD TN TX UT VA VI VT WA WV WI WY]
    end

    def income_form_for(application, applicant, income)
      url = if income.new_record?
              application_applicant_incomes_path(application, applicant)
            else
              application_applicant_income_path(@application, @applicant, income)
            end

      form_for income, url: url, remote: true do |f|
        yield f
      end
    end

    def benefit_form_for(application, applicant, benefit)
      url = if benefit.new_record?
              application_applicant_benefits_path(application, applicant)
            else
              application_applicant_benefit_path(@application, @applicant, benefit)
            end

      form_for benefit, url: url, remote: true do |f|
        yield f
      end
    end

    def deduction_form_for(application, applicant, deduction)
      url = if deduction.new_record?
              application_applicant_deductions_path(application, applicant)
            else
              application_applicant_deduction_path(@application, @applicant, deduction)
            end

      form_for deduction, url: url, remote: true do |f|
        yield f
      end
    end

    def income_and_deductions_for(applicant)
      applicant.incomes + applicant.deductions
    end

    def income_and_deductions_for_any(application)
      return false if application.blank?
      application.applicants.any? {|applicant| income_and_deductions_for(applicant).present?}
    end

    def start_to_end_dates(embedded_document)
      start_date = embedded_document.start_on
      end_date = embedded_document.end_on

      if end_date.nil?
        "#{start_date} - Present"
      else
        "#{start_date} - #{end_date}"
      end
    end

    def income_and_deductions_edit(application, applicant, embedded_document)
      if embedded_document.class == FinancialAssistance::Deduction
        application_applicant_deductions_path(application, applicant)
      elsif [FinancialAssistance::Income::JOB_INCOME_TYPE_KIND, FinancialAssistance::Income::NET_SELF_EMPLOYMENT_INCOME_KIND].include? embedded_document.kind
        application_applicant_incomes_path(application, applicant)
      else
        other_application_applicant_incomes_path(application, applicant)
      end
    end

    def show_net_amount_for(other_income)
      other_income.kind == "capital_gains" || other_income.kind == "farming_and_fishing"
    end

    def decode_msg(encoded_msg)
      if encoded_msg == '101'
        'faa.acdes_lookup'
      elsif encoded_msg == '010'
        'faa.curam_lookup'
      end
    end

    def format_phone(phone)
      return '' unless phone && phone.size == 10
      number_to_phone(phone, area_code: true)
    end

    def format_benefit_cost(cost, frequency)
      return '' if cost.nil? || frequency.nil?
      "$" + cost.to_s + " " + frequency.to_s.capitalize
    end

    def faa_relationship_options(dependent, _referer)
      relationships = FinancialAssistance::Relationship::RELATIONSHIPS_UI
      options_for_select(relationships.map{|r| [r.to_s.humanize, r.to_s] }, selected: dependent.relation_with_primary)
    end

    def applicant_currently_enrolled
      if FinancialAssistanceRegistry[:has_enrolled_health_coverage].setting(:currently_enrolled).item
        'Is this person currently enrolled in health coverage? *'
      elsif FinancialAssistanceRegistry[:has_enrolled_health_coverage].setting(:currently_enrolled_with_hra).item
        'Is this person currently enrolled in health coverage or getting help paying for health coverage through a Health Reimbursement Arrangement? *'
      else
        ''
      end
    end

    def applicant_currently_enrolled_key
      if FinancialAssistanceRegistry[:has_enrolled_health_coverage].setting(:currently_enrolled).item
        'has_enrolled_health_coverage'
      elsif FinancialAssistanceRegistry[:has_enrolled_health_coverage].setting(:currently_enrolled_with_hra).item
        'has_enrolled_health_coverage_from_hra'
      else
        ''
      end
    end

    def applicant_eligibly_enrolled
      if FinancialAssistanceRegistry[:has_eligible_health_coverage].setting(:currently_eligible).item
        'Does this person currently have access to other health coverage that they are not enrolled in, including coverage they could get through another person? *'
      elsif FinancialAssistanceRegistry[:has_eligible_health_coverage].setting(:currently_eligible_with_hra).item && FinancialAssistanceRegistry.feature_enabled?(:minimum_value_standard_question)
        'Does this person currently have access to health coverage or a Health Reimbursement Arrangement that they are not enrolled in? *'
      elsif FinancialAssistanceRegistry[:has_eligible_health_coverage].setting(:currently_eligible_with_hra).item
        'Does this person currently have access to health coverage or a Health Reimbursement Arrangement that they are not enrolled in (including through another person, like a spouse or parent)? *'
      else
        ''
      end
    end

    def applicant_eligibly_enrolled_key
      if FinancialAssistanceRegistry[:has_eligible_health_coverage].setting(:currently_eligible).item
        'has_eligible_health_coverage'
      elsif FinancialAssistanceRegistry[:has_eligible_health_coverage].setting(:currently_eligible_with_hra).item
        'has_eligible_health_coverage_from_hra'
      else
        ''
      end
    end

    def show_naturalized_citizen_container(applicant)
      applicant&.us_citizen
    end

    def show_immigration_status_container(applicant)
      applicant&.us_citizen == false
    end

    def show_tribal_container(applicant)
      applicant&.indian_tribe_member
    end

    def show_naturalization_doc_type(applicant)
      show_naturalized_citizen_container(applicant) && applicant&.naturalized_citizen
    end

    def show_immigration_doc_type(applicant)
      show_immigration_status_container(applicant) && applicant&.eligible_immigration_status
    end

    def show_vlp_documents_container(applicant)
      show_naturalization_doc_type(applicant) || show_immigration_doc_type(applicant)
    end

    def member_name_by_id(id)
      ::FinancialAssistance::Applicant.find(id)&.full_name
    end

    def immigration_document_options_submission_url(application, model)
      if model.try(:persisted?)
        { :remote => true, method: :put, :url => application_applicant_path(application_id: application.id, id: model.id), :as => :applicant }
      else
        { :remote => true, method: :post, :url => "/applications/#{application.id}/applicants", :as => :applicant }
      end
    end

    def humanize_relationships
      FinancialAssistance::Relationship::RELATIONSHIPS_UI.map {|r| [r.to_s.humanize, r.to_s] }
    end

    def calculated_application_year
      FinancialAssistanceRegistry[:enrollment_dates].setting(:application_year).constantize.item.call.value!
    end

    def human_boolean(boolean)
      if boolean
        'Yes'
      elsif boolean == false
        'No'
      else
        'N/A'
      end
    end

    def capitalize_full_name(full_name)
      full_name.split.map(&:capitalize).join(" ")
    end

    def all_applications_closed?(applications)
      applications.count == applications.closed.count
    end

    def application_state_for_display(application)
      return 'IRS Consent' if application.income_verification_extension_required?
      return 'Submission Error' if application.mitc_magi_medicaid_eligibility_request_errored?
      return 'Submission Error' if FinancialAssistanceRegistry[:application_submission_error_status].enabled? && application.aasm_state == "submitted" && DateTime.now.utc > application.submitted_at + 2.minutes

      application.aasm_state.titleize
    end

    def fetch_counties_by_zip(address)
      return [] unless address&.zip

      BenefitMarkets::Locations::CountyZip.where(zip: address.zip.slice(/\d{5}/)).pluck(:county_name).uniq
    end

    def full_name(applicant)
      applicant.full_name.split.map(&:capitalize).join(' ')
    end

    def display_csr(applicant)
      applicant.csr_eligibility_kind.split('_').last.capitalize.tap do |csr|
        return csr if csr == 'Limited'
        return "#{csr}%"
      end
    end

    def do_not_allow_copy?(application, current_user)
      return true if prospective_year_application?(application)

      application.is_draft? || application.is_closed? || (application.imported? ? !current_user.has_hbx_staff_role? : false)
    end

    # Restrict the ability to copy prospective year applications until the start of OE for all users, consumers, admin, brokers, etc.
    def prospective_year_application?(application)
      return false unless FinancialAssistanceRegistry.feature_enabled?(:block_prospective_year_application_copy_before_oe)
      return false if HbxProfile.current_hbx.under_open_enrollment?

      # Handles applications which are not submitted.
      return false if application.assistance_year.nil?

      TimeKeeper.date_of_record.year < application.assistance_year
    end

    # Does this employer offer a health plan that meets the minimum value standard and is considered affordable for the employee and family?
    def display_minimum_value_standard_question?(insurance_kind)
      FinancialAssistanceRegistry.feature_enabled?(:minimum_value_standard_question) && insurance_kind == 'employer_sponsored_insurance'
    end

    # is this an eligible esi benefit
    def display_esi_fields?(insurance_kind, kind)
      ['employer_sponsored_insurance', 'health_reimbursement_arrangement'].include?(insurance_kind) && (kind == "is_eligible" || !FinancialAssistanceRegistry.feature_enabled?(:short_enrolled_esi_forms))
    end

    def assistance_year
      return @assistance_year if defined? @assistance_year

      year_selection_enabled = FinancialAssistanceRegistry.feature_enabled?(:iap_year_selection) && (HbxProfile.current_hbx.under_open_enrollment? || FinancialAssistanceRegistry.feature_enabled?(:iap_year_selection_form))
      @assistance_year = year_selection_enabled ? @application.assistance_year.to_s : FinancialAssistanceRegistry[:enrollment_dates].setting(:application_year).item.constantize.new.call.value!.to_s
    end

    def applicant_faa_nav_options(application, applicant)
      [
        {step: 1, label: l10n('faa.nav.tax_info'), link: go_to_step_application_applicant_path(application, applicant, 1), step_complete: applicant.tax_info_complete? },
        {step: 2, label: l10n('faa.nav.job_income'), link: application_applicant_incomes_path(application, applicant), step_complete: applicant.embedded_document_section_entry_complete?(:income) },
        {step: 3, label: l10n('faa.nav.other_income'), link: other_application_applicant_incomes_path(application, applicant), step_complete: applicant.embedded_document_section_entry_complete?(:other_income) },
        {step: 4, label: l10n('faa.nav.income_adjustments'), link: application_applicant_deductions_path(application, applicant), step_complete: applicant.embedded_document_section_entry_complete?(:income_adjustment) },
        {step: 5, label: l10n('faa.nav.health_coverage'), link: application_applicant_benefits_path(application, applicant), step_complete: applicant.embedded_document_section_entry_complete?(:health_coverage) },
        {step: 6, label: l10n('faa.nav.other_questions'), link: other_questions_application_applicant_path(application, applicant), step_complete: applicant.other_questions_complete? },
      ]
    end

    def no_applicant_faa_nav_options(application)
      step1_link = (application.present? && application.is_draft?) ? financial_assistance.edit_application_path(application) : "javascript:void(0);"
      links = [
        {step: 1, label: l10n('faa.nav.family_info'), link: step1_link},
      ]
      relationship_step = {step: 2, label: l10n('faa.nav.family_relationships'), link: "javascript:void(0);"}
      review_step = {step: 2, label: l10n('faa.nav.review'), link: "javascript:void(0);"}
      if application && application.incomplete_applicants?
        relationship_step[:link] = nil
      elsif application && application.applicants.count > 1 && application.is_draft?
        relationship_step[:link] = financial_assistance.application_relationships_path(application)
      end

      if application.applicants.count > 1
        links << relationship_step
        review_step[:step] = 3
      end

      review_step[:link] = financial_assistance.review_and_submit_application_path(application) if application.present? && application.ready_for_attestation? && application.is_draft?
      links << review_step
    end
  end
end
