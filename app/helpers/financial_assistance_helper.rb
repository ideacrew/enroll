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

  def eligible_applicants application_id, eligibility_flag
    application = FinancialAssistance::Application.find(application_id)
    application.applicants.where(eligibility_flag => true).map(&:person).map(&:full_name).map(&:titleize)
  end

  def applicant_age applicant
    now = Time.now.utc.to_date
    dob = applicant.family_member.person.dob
    age = now.year - dob.year - ((now.month > dob.month || (now.month == dob.month && now.day >= dob.day)) ? 0 : 1)
  end

  def activer_for(target)
    if controller_name == 'applicants'
      if action_name == 'step' and defined? @current_step
        if @current_step.to_i == 1
          ''
        elsif @current_step.to_i == 2 and target == 'income_and_coverage'
          'activer'
        end
      elsif action_name == 'other_questions'
        if target == 'other_questions'
          ''
        else
          'activer'
        end
      else
        ''
      end
    elsif controller_name == 'incomes'
      if ['income_and_coverage', 'tax_info'].include?(target)
        'activer'
      else
        ''
      end
    elsif controller_name == "deductions"
      if ['income_and_coverage', 'tax_info', 'income'].include?(target)
        'activer'
      else
        ''
      end
    elsif controller_name == "benefits"
      if ['income_and_coverage', 'tax_info', 'income', 'income_adjustments'].include?(target)
        'activer'
      else
        ''
      end
    end
  end

  def find_application_path(application)
    if application.incomplete_applicants?
      go_to_step_financial_assistance_application_applicant_path application, application.next_incomplete_applicant, 1
    else
      if action_name == "save_questions"
        edit_financial_assistance_application_path(application)
      else
        review_and_submit_financial_assistance_application_path application
      end
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

  def show_component(url)
    if url.split('/')[2] == "consumer_role" || url.split('/')[1] == "insured" && url.split('/')[2] == "interactive_identity_verifications" || url.split('/')[1] == "financial_assistance" && url.split('/')[2] == "applications" || url.split('/')[1] == "insured" && url.split('/')[2] == "family_members" || url.include?("family_relationships")
      false
    else
      true
    end
  end
end
