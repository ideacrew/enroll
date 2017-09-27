module FinancialAssistanceHelper
  def to_est datetime
    datetime.in_time_zone("Eastern Time (US & Canada)") if datetime.present?
  end

  def total_aptc_sum application_id
    application = FinancialAssistance::Application.find(application_id)
    sum = 0.0
    application.tax_households.each do |thh|
      sum = sum + thh.preferred_eligibility_determination.max_aptc
    end
    return sum
  end

  def total_aptc_across_tax_households(application_id)
    application = FinancialAssistance::Application.find(application_id)
    total_aptc = 0.0
    application.tax_households.each do |thh|
      total_aptc += thh.preferred_eligibility_determination.max_aptc
    end
    total_aptc
  end

  def eligible_applicants application_id, eligibility_flag
    application = FinancialAssistance::Application.find(application_id)
    application.active_applicants.where(eligibility_flag => true).map(&:person).map(&:full_name).map(&:titleize)
  end

  def applicant_age applicant
    now = Time.now.utc.to_date
    dob = applicant.family_member.person.dob
    age = now.year - dob.year - ((now.month > dob.month || (now.month == dob.month && now.day >= dob.day)) ? 0 : 1)
  end

  def li_nav_classes_for(target)
    current = if controller_name == 'applications'
      if action_name == 'edit'
        :household_info
      else
        :review_and_submit
      end
    elsif controller_name == 'family_members'
      :household_info
    elsif controller_name == 'applicants'
      if action_name == 'step' and @current_step.try(:to_i) == 1
        :income_and_coverage
      elsif action_name == 'step' and @current_step.try(:to_i) == 2
        :tax_info
      elsif action_name == 'other_questions'
        :other_questions
      end
    elsif controller_name == 'incomes'
      if action_name == 'other'
        :other_income
      else
        :income
      end
    elsif controller_name == 'deductions'
      :income_adjustments
    elsif controller_name == 'benefits'
      :health_coverage
    elsif controller_name == 'family_relationships'
      :relationships
    end

    order = [:applications, :household_info, :relationships, :income_and_coverage, :tax_info, :income, :other_income, :income_adjustments, :health_coverage, :other_questions, :review_and_submit]

    unless current.blank?
      if target == current
        'activer active'
      elsif order.index(target) < order.index(current)
        'activer'
      else
        ''
      end
    else
      ''
    end
  end

  def find_next_application_path(application)
    if application.incomplete_applicants?
      go_to_step_financial_assistance_application_applicant_path application, application.next_incomplete_applicant, 1
    else
      review_and_submit_financial_assistance_application_path application
    end
  end

  def find_previous_from_step_one
    model_name = @model.class.to_s.split('::').last.downcase
    if  model_name == "applicant"
      edit_financial_assistance_application_path(@application)
    elsif model_name == "application"
      review_and_submit_financial_assistance_application_path(@application)
    else
      send("financial_assistance_application_applicant_#{model_name.pluralize}_path", @application, @applicant)
    end
  end

  def find_applicant_path(application, applicant, options={})
    document_flow = ['incomes', 'deductions', 'benefits']
    next_path = document_flow.find do |embeded_document|
      # this is a complicated condition but we need to make sure we don't work backwards in the flow from incomes to deductions to benefits
      # so if a current option is passed in we won't consider anything before it
      # if a current option is not passed then .index will return nil
      # and instead we'll short circuit by checking that -1 is less then i, which always would be true
      (document_flow.index(options[:current]) || -1) < document_flow.index(embeded_document) and applicant.send(embeded_document).present?
    end
    next_path ? send("financial_assistance_application_applicant_#{next_path}_path", application, applicant) : other_questions_financial_assistance_application_applicant_path(application, applicant)
  end

  def find_previous_applicant_path(application, applicant, options={})
    reverse_document_flow = ['benefits', 'deductions', 'incomes']
    previous_path = reverse_document_flow.find do |embeded_document|
      # this is a complicated condition but we need to make sure we don't work backwards in the flow from incomes to deductions to benefits
      # so if a current option is passed in we won't consider anything before it
      # if a current option is not passed then .index will return nil
      # and instead we'll short circuit by checking that -1 is less then i, which always would be true
      (reverse_document_flow.index(options[:current]) || -1) < reverse_document_flow.index(embeded_document) and applicant.send(embeded_document).present?
    end
    previous_path ? send("financial_assistance_application_applicant_#{previous_path}_path", application, applicant) : go_to_step_financial_assistance_application_applicant_path(application, applicant, 2)
  end

  def show_component(url)
    if url.split('/')[2] == "consumer_role" || url.split('/')[1] == "insured" && url.split('/')[2] == "interactive_identity_verifications" || url.split('/')[1] == "financial_assistance" && url.split('/')[2] == "applications" || url.split('/')[1] == "insured" && url.split('/')[2] == "family_members" || url.include?("family_relationships")
      false
    else
      true
    end
  end

  def left_nav_css(conditional)
    'cna disabled' unless conditional
  end

  def show_faa_status
    return true if (controller_name == 'applications' and action_name == 'edit') or controller_name == 'family_relationships'
    return true if ( controller_name == 'family_members' and (action_name == 'create' or action_name == 'destroy')) # On AJAX renders for create / destory
    return false
  end

  def claim_eligible_tax_dependents
    @application.active_applicants.inject({}) do |memo, applicant|
      memo.merge! applicant.person.full_name => applicant.id.to_s if (applicant != @applicant && applicant.is_required_to_file_taxes? && applicant.claimed_as_tax_dependent_by != @applicant.id)
      memo
    end
  end

  def frequency_kind_options
    %w(biweekly daily half_yearly monthly quarterly weekly yearly)
  end

  def state_options
    %w(AL AK AZ AR CA CO CT DE DC FL GA HI ID IL IN IA KS KY LA ME MD MA MI MN MS MO MT NE NV NH NJ NY NC ND OH OK OR PA PR RI SC SD TN TX UT VA VI VT WA WV WI WY)
  end

  def income_form_for(application, applicant, income)
    url = if income.new_record?
      financial_assistance_application_applicant_incomes_path(application, applicant)
    else
      financial_assistance_application_applicant_income_path(@application, @applicant, income)
    end

    form_for income, url: url, remote: true do |f|
      yield f
    end
  end

  def benefit_form_for(application, applicant, benefit)
    url = if benefit.new_record?
      financial_assistance_application_applicant_benefits_path(application, applicant)
    else
      financial_assistance_application_applicant_benefit_path(@application, @applicant, benefit)
    end

    form_for benefit, url: url, remote: true do |f|
      yield f
    end
  end

  def deduction_form_for(application, applicant, deduction)
    url = if deduction.new_record?
      financial_assistance_application_applicant_deductions_path(application, applicant)
    else
      financial_assistance_application_applicant_deduction_path(@application, @applicant, deduction)
    end

    form_for deduction, url: url, remote: true do |f|
      yield f
    end
  end

  def redirect_path_after_applicant_update(request_referrer_url, application, applicant)
    url_key = request_referrer_url.split('/').last
    case url_key
    when 'incomes'
      other_financial_assistance_application_applicant_incomes_path(application, applicant)
    when 'other'
      financial_assistance_application_applicant_deductions_path(application, applicant)
    when 'deductions'
      financial_assistance_application_applicant_benefits_path(application, applicant)
    when 'benefits'
      other_questions_financial_assistance_application_applicant_path(application, applicant)
    end
  end

  def embedded_document_section_entry_complete?(applicant, embedded_document)
    case embedded_document
    when :income
      return false if  applicant.has_job_income.nil? || applicant.has_self_employment_income.nil?
      if applicant.has_job_income && applicant.has_self_employment_income
        return applicant.incomes.jobs.present? && applicant.incomes.self_employment.present?
      elsif applicant.has_job_income && !applicant.has_self_employment_income
        return applicant.incomes.jobs.present? && applicant.incomes.self_employment.blank?
      elsif !applicant.has_job_income && applicant.has_self_employment_income
        return applicant.incomes.jobs.blank? && applicant.incomes.self_employment.present?
      else
        return applicant.incomes.jobs.blank? && applicant.incomes.self_employment.blank?
      end
    when :other_income
      return false if  applicant.has_other_income.nil?
      if applicant.has_other_income
        return applicant.incomes.other.present?
      else
        return applicant.incomes.other.blank?
      end
    when :income_adjustments
      return false if  applicant.has_deductions.nil?
      if applicant.has_deductions
        return applicant.deductions.present?
      else
        return applicant.deductions.blank?
      end
    when :health_coverage
      return false if  applicant.has_enrolled_health_coverage.nil? || applicant.has_eligible_health_coverage.nil?
      if applicant.has_enrolled_health_coverage && applicant.has_eligible_health_coverage
        return applicant.benefits.enrolled.present? && applicant.benefits.eligible.present?
      elsif applicant.has_enrolled_health_coverage && !applicant.has_eligible_health_coverage
        return applicant.benefits.enrolled.present? && applicant.benefits.eligible.blank?
      elsif !applicant.has_enrolled_health_coverage && applicant.has_eligible_health_coverage
        return applicant.benefits.enrolled.blank? && applicant.benefits.eligible.present?
      else
        return applicant.benefits.enrolled.blank? && applicant.benefits.eligible.blank?
      end
    end
  end
end
