# frozen_string_literal: true

module FinancialAssistance
  class ApplicationsController < FinancialAssistance::ApplicationController

    before_action :set_current_person

    include ::UIHelpers::WorkflowController
    include Acapi::Notifiers
    require 'securerandom'

    before_action :check_eligibility, only: [:create, :get_help_paying_coverage_response, :copy]
    before_action :init_cfl_service, only: [:review_and_submit, :raw_application]

    layout "financial_assistance_nav", only: %i[edit step review_and_submit eligibility_response_error application_publish_error]

    def index
      @applications = ::FinancialAssistance::Application.where(family_id: get_current_person.financial_assistance_identifier)
    end

    def new
      @application = FinancialAssistance::Application.new
    end

    def edit
      save_faa_bookmark(request.original_url)
      set_admin_bookmark_url

      @application = ::FinancialAssistance::Application.find_by(id: params[:id], family_id: get_current_person.financial_assistance_identifier)

      load_support_texts
    end

    def step # rubocop:disable Metrics/CyclomaticComplexity
      save_faa_bookmark(request.original_url.gsub(%r{/step.*}, "/step/#{@current_step.to_i}"))
      set_admin_bookmark_url
      flash[:error] = nil
      model_name = @model.class.to_s.split('::').last.downcase
      model_params = params[model_name]
      @model.clean_conditional_params(model_params) if model_params.present?
      @model.assign_attributes(permit_params(model_params)) if model_params.present?

      # rubocop:disable Metrics/BlockNesting
      if params.key?(model_name)
        if @model.save
          @current_step = @current_step.next_step if @current_step.next_step.present?
          @model.update_attributes!(workflow: { current_step: @current_step.to_i })
          if params[:commit] == "Submit Application"
            dummy_data_5_year_bar(@application)
            @application.submit! if @application.complete?
            publish_result = FinancialAssistance::Operations::Application::RequestDetermination.new.call(application_id: @application.id)
            if publish_result.success?
              #dummy_data_for_demo(params) if @application.complete? && @application.is_submitted? #For_Populating_dummy_ED_for_DEMO #temporary
              redirect_to wait_for_eligibility_response_application_path(@application)
            else
              @application.unsubmit!
              redirect_to application_publish_error_application_path(@application)
            end
          else
            render 'workflow/step'
          end
        else
          @model.assign_attributes(workflow: { current_step: @current_step.to_i })
          @model.save!(validate: false)
          flash[:error] = build_error_messages(@model)
          render 'workflow/step'
        end
      else
        render 'workflow/step'
      end
      # rubocop:enable Metrics/BlockNesting
    end


    #checklist
    # - data to enroll
    ##  -

    # - data to faa
    ## - if app in draft , update applicants
    ## - if application not in draft , create new draft application from existing app and create/update respective applicants

    def copy
      service = FinancialAssistance::Services::ApplicationService.new(application_id: params[:id])
      @application = service.copy!
      redirect_to edit_application_path(@application)
    end

    def help_paying_coverage
    end

    def render_message
      @message = params["message"]
    end

    def uqhp_flow
      ::FinancialAssistance::Application.where(aasm_state: "draft", family_id: get_current_person.financial_assistance_identifier).destroy_all
      redirect_to main_app.insured_family_members_path(consumer_role_id: @person.consumer_role.id)
    end

    def redirect_to_msg
      redirect_to render_message_applications_path(message: @message)
    end

    def application_checklist
      @application = FinancialAssistance::Application.where(id: params[:id], family_id: get_current_person.financial_assistance_identifier).first
      save_faa_bookmark(request.original_url)
      set_admin_bookmark_url
    end

    def review_and_submit
      save_faa_bookmark(request.original_url)
      set_admin_bookmark_url
      @application = ::FinancialAssistance::Application.find_by(id: params[:id], family_id: get_current_person.financial_assistance_identifier)
      @all_relationships = @application.relationships
      @applicants = @application.active_applicants if @application.present?
      redirect_to applications_path if @application.blank?
    end

    def review
      save_faa_bookmark(request.original_url)
      @application = FinancialAssistance::Application.where(id: params["id"]).first
      @applicants = @application.active_applicants if @application.present?
      redirect_to applications_path if @application.blank?
    end

    def raw_application
      @application = FinancialAssistance::Application.where(id: params['id']).first

      if @application.nil? || @application.is_draft?
        redirect_to applications_path
      else
        redirect_to applications_path unless @application.family_id == get_current_person.financial_assistance_identifier

        @applicants = @application.active_applicants
        @all_relationships = @application.relationships
        @demographic_hash={}
        @income_coverage_hash={}

        @applicants.each do |applicant|
          @demographic_hash[applicant.id] = generate_demographic_hash(applicant)
          @income_coverage_hash[applicant.id] = generate_income_coverage_hash(applicant)
        end
      end
    end

    def wait_for_eligibility_response
      save_faa_bookmark(applications_path)
      set_admin_bookmark_url
      @application = ::FinancialAssistance::Application.find_by(id: params[:id], family_id: get_current_person.financial_assistance_identifier)

      render layout: 'financial_assistance'
    end

    def eligibility_results
      save_faa_bookmark(request.original_url)
      set_admin_bookmark_url
      @application = ::FinancialAssistance::Application.find_by(id: params[:id], family_id: get_current_person.financial_assistance_identifier)

      render layout: (params.keys.include?('cur') ? 'financial_assistance_nav' : 'financial_assistance')
    end

    def application_publish_error
      save_faa_bookmark(request.original_url)
      set_admin_bookmark_url
      @application = ::FinancialAssistance::Application.find_by(id: params[:id], family_id: get_current_person.financial_assistance_identifier)
    end

    def eligibility_response_error
      save_faa_bookmark(request.original_url)
      set_admin_bookmark_url
      @application = ::FinancialAssistance::Application.find_by(id: params[:id], family_id: get_current_person.financial_assistance_identifier)
      @application.update_attributes(determination_http_status_code: 999) if @application.determination_http_status_code.nil?
      @application.send_failed_response
    end

    def check_eligibility_results_received
      application = ::FinancialAssistance::Application.find_by(id: params[:id], family_id: get_current_person.financial_assistance_identifier)
      render :plain => (application.success_status_codes?(application.determination_http_status_code) && application.determined?).to_s
    end

    def checklist_pdf
      send_file(FinancialAssistance::Engine.root.join('db','documents', 'ivl_checklist.pdf').to_s, :disposition => "inline", :type => "application/pdf")
    end

    private

    def init_cfl_service
      @cfl_service = ::FinancialAssistance::Services::ConditionalFieldsLookupService.new
    end

    def check_eligibility
      call_service
      return if params['action'] == "get_help_paying_coverage_response"
      [(flash[:error] = helpers.l10n(helpers.decode_msg(@message))), (redirect_to applications_path)] unless @assistance_status
    end

    def call_service
      if EnrollRegistry[:faa_ext_service].setting(:aceds_curam).item
        person = FinancialAssistance::Factories::AssistanceFactory.new(@person)
        @assistance_status, @message = person.search_existing_assistance
      else
        @assistance_status = true
        @message = nil
      end
    end

    # TODO: Remove dummy data before prod
    def dummy_data_for_demo(_params)
      #Dummy_ED
      coverage_year = FinancialAssistanceRegistry[:application_year].item.call.value!
      @model.update_attributes!(aasm_state: "determined", assistance_year: coverage_year, determination_http_status_code: 200)

      @model.eligibility_determinations.each do |ed|
        ed.update_attributes(max_aptc: 200.00,
                             csr_percent_as_integer: 73,
                             is_eligibility_determined: true,
                             effective_starting_on: Date.new(coverage_year, 0o1, 0o1),
                             determined_at: TimeKeeper.datetime_of_record - 30.days,
                             source: "Faa")
        ed.applicants.first.update_attributes!(is_medicaid_chip_eligible: false, is_ia_eligible: false, is_without_assistance: true) if ed.applicants.count > 0
        ed.applicants.second.update_attributes!(is_medicaid_chip_eligible: false, is_ia_eligible: true, is_without_assistance: false) if ed.applicants.count > 1
        ed.applicants.third.update_attributes!(is_medicaid_chip_eligible: true, is_ia_eligible: false, is_without_assistance: false) if ed.applicants.count > 2

        #Update the Income and MEC verifications to Outstanding
        @model.applicants.each do |applicant|
          applicant.update_attributes!(:assisted_income_validation => "outstanding", :assisted_mec_validation => "outstanding", aasm_state: "verification_outstanding")
          applicant.verification_types.each { |verification| verification.update_attributes!(validation_status: "outstanding") }
        end
      end
    end

    # TODO: Remove dummy stuff before prod
    def dummy_data_5_year_bar(application)
      return unless application.primary_applicant.present? && ["bar5"].include?(application.primary_applicant&.last_name&.downcase)
      application.active_applicants.each { |applicant| applicant.update_attributes!(is_subject_to_five_year_bar: true, is_five_year_bar_met: false)}
    end

    def build_error_messages(model)
      model.valid? ? nil : model.errors.messages.first.flatten.flatten.join(',').gsub(",", " ").titleize
    end

    def hash_to_param(param_hash)
      ActionController::Parameters.new(param_hash)
    end

    def permit_params(attributes)
      attributes.permit!
    end

    def find
      @application = ::FinancialAssistance::Application.find_by(id: params[:id], family_id: get_current_person.financial_assistance_identifier) if params.key?(:id)
    end

    def save_faa_bookmark(url)
      current_person = get_current_person
      return if current_person.consumer_role.blank?
      current_person.consumer_role.update_attribute(:bookmark_url, url) if current_person.consumer_role.identity_verified?
    end

    def generate_demographic_hash(applicant)
      {
        "Are you a US Citizen or US National?" => human_boolean(applicant.citizen_status),
        "Are you a naturalized citizen?" => human_boolean(applicant.naturalized_citizen),
        "Do you have eligible immigration status?" => human_boolean(applicant.eligible_immigration_status),
        "Document_type" => check_citizen_immigration_status?(applicant) ? applicant.vlp_subject : 'N/A',
        "citizenship_number" => check_citizen_immigration_status?(applicant) ? applicant.citizenship_number : 'N/A',
        "alien_number" => check_citizen_immigration_status?(applicant) ? applicant.alien_number : 'N/A',
        "i94_number" => check_citizen_immigration_status?(applicant) ? applicant.i94_number : 'N/A',
        "visa_number" => check_citizen_immigration_status?(applicant) ? applicant.visa_number : 'N/A',
        "passport_number" => check_citizen_immigration_status?(applicant) ? applicant.passport_number : 'N/A',
        "sevis_id" => check_citizen_immigration_status?(applicant) ? applicant.sevis_id : 'N/A',
        "naturalization_number" => check_citizen_immigration_status?(applicant) ? applicant.naturalization_number : 'N/A',
        "receipt_number" => check_citizen_immigration_status?(applicant) ? applicant.receipt_number : 'N/A',
        "card_number" => check_citizen_immigration_status?(applicant) ? applicant.card_number : 'N/A',
        "country_of_citizenship" => check_citizen_immigration_status?(applicant) ? applicant.country_of_citizenship : 'N/A',
        "vlp_description" => check_citizen_immigration_status?(applicant) ? applicant.vlp_description : 'N/A',
        "expiration_date" => check_citizen_immigration_status?(applicant) ? applicant.expiration_date : 'N/A',
        "issuing_country" => check_citizen_immigration_status?(applicant) ? applicant.issuing_country : 'N/A',
        "Are you a member of an American Indian or Alaska Native Tribe?" => human_boolean(applicant.indian_tribe_member),
        "Are you currently incarcerated?" => human_boolean(applicant.is_incarcerated),
        "What is your race/ethnicity? (OPTIONAL - check all that apply)" => applicant.ethnicity
      }
    end

    def check_citizen_immigration_status?(applicant)
      applicant.naturalized_citizen.present? || applicant.eligible_immigration_status.present?
    end

    def generate_income_coverage_hash(applicant)
      {"info" =>
           {"TAX INFO" => generate_tax_info_hash(applicant),
            "INCOME" => generate_income_hash(applicant),
            "INCOME ADJUSTMENTS" => {
              "Does this person expect to have adjustments to income in #{@application.assistance_year}?" => human_boolean(applicant.has_deductions)
            },
            "HEALTH COVERAGE" => {
              "Is this person currently enrolled in health coverage?" => human_boolean(applicant.has_enrolled_health_coverage),
              "Does this person currently have access to other health coverage, including through another person?" => human_boolean(applicant.has_eligible_health_coverage)
            },
            "OTHER QUESTIONS" => generate_other_questions_hash(applicant)}}
    end

    def generate_tax_info_hash(applicant)
      {
        "Will this Person file taxes for #{@application.assistance_year}?" => human_boolean(applicant.is_required_to_file_taxes),
        "Will this person be claimed as a tax dependent for #{@application.assistance_year}? *" => human_boolean(applicant.is_claimed_as_tax_dependent),
        "Will this person be filing jointly?" => human_boolean(applicant.is_joint_tax_filing),
        "This person will be claimed as a dependent by" => applicant.claimed_as_tax_dependent_by ? @applicants.find(applicant.claimed_as_tax_dependent_by).full_name : nil
      }
    end

    def generate_income_hash(applicant)
      {
        "Does this person have income from an employer (wages, tips, bonuses, etc.) in #{@application.assistance_year}?" => human_boolean(applicant.has_job_income),
        "jobs" => generate_employment_hash(applicant.incomes.jobs),
        "Does this person expect to receive self-employment income in #{@application.assistance_year}? *" => human_boolean(applicant.has_self_employment_income),
        "Does this person expect to have income from other sources in 2021?" => human_boolean(applicant.has_other_income)
      }
    end

    def generate_other_questions_hash(applicant)
    {
      "Has this person applied for an SSN" => human_boolean(applicant.is_ssn_applied),
      "Why doesn't this person have an SSN?" => applicant.non_ssn_apply_reason.to_s.present? ? applicant.non_ssn_apply_reason.to_s : 'N/A',
      "Is this person pregnant?" => human_boolean(applicant.is_pregnant),
      "Pregnancy due date?" => applicant.pregnancy_due_on.to_s.present? ? applicant.pregnancy_due_on.to_s : 'N/A',
      "How many children is this person expecting?" => applicant.children_expected_count.present? ? applicant.children_expected_count : 'N/A',
      "Was this person pregnant in the last 60 days?" => human_boolean(applicant.is_post_partum_period),
      "Pregnancy end on date" => applicant.pregnancy_end_on.to_s.present? ? applicant.pregnancy_end_on.to_s : 'N/A',
      "Was this person on Medicaid during pregnancy?" => human_boolean(applicant.is_enrolled_on_medicaid),
      "Was this person in foster care at age 18 or older?" => human_boolean(applicant.is_former_foster_care),
      "Where was this person in foster care?" => applicant.foster_care_us_state.present? ? applicant.foster_care_us_state : 'N/A',
      "How old was this person when they left foster care?" => applicant.age_left_foster_care.present? ? applicant.age_left_foster_care : 'N/A',
      "Was this person enrolled in Medicaid when they left foster care?" => human_boolean(applicant.had_medicaid_during_foster_care),
      "Is this person a student?" => human_boolean(applicant.is_student),
      "What is the type of student?" => applicant.student_kind.present? ? applicant.student_kind : 'N/A',
      "Student status end on date?" => applicant.student_status_end_on.present? ? applicant.student_status_end_on : 'N/A',
      "What type of school do you go to?" => human_boolean(applicant.student_school_kind),
      "Is this person blind?" => human_boolean(applicant.is_self_attested_blind),
      "Does this person need help with daily life activities, such as dressing or bathing?" => human_boolean(applicant.has_daily_living_help),
      "Does this person need help paying for any medical bills from the last 3 months?" => human_boolean(applicant.has_daily_living_help),
      "Does this person have a disability?" => human_boolean(applicant.is_physically_disabled)
      }
    end

    def generate_employment_hash(jobs)
      job_hash = {}
      jobs.each do |job|
        job_hash[job.id] = {
          "Employer Name" => job.employer_name,
          "EMPLOYER ADDRESSS LINE 1" => job.employer_address.address_1,
          "EMPLOYER ADDRESSS LINE 2" => job.employer_address.address_2,
          "CITY" => job.employer_address.city,
          "STATE" => job.employer_address.state,
          "ZIP" => job.employer_address.zip,
          "EMPLOYER PHONE " => job.employer_phone.full_phone_number
        }
      end
      job_hash
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
  end
end
