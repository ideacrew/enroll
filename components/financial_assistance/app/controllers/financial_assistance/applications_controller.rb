# frozen_string_literal: true

module FinancialAssistance
  class ApplicationsController < FinancialAssistance::ApplicationController

    before_action :set_current_person

    include ::UIHelpers::WorkflowController
    include Acapi::Notifiers
    include FinancialAssistance::L10nHelper
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

      # @application = ::FinancialAssistance::Application.find_by(id: params[:id], family_id: get_current_person.financial_assistance_identifier)
      @application = ::FinancialAssistance::Application.find_by(id: params[:id])

      load_support_texts
    end

    # rubocop:disable Metrics/AbcSize
    def step
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
            @application.submit! if @application.complete?
            publish_result = determination_request_class.new.call(application_id: @application.id)
            if publish_result.success?
              redirect_to wait_for_eligibility_response_application_path(@application)
            else
              @application.unsubmit!
              redirect_to application_publish_error_application_path(@application), flash: { error: "Submission Error: #{publish_result.failure}" }
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
    # rubocop:enable Metrics/AbcSize

    def copy
      service = FinancialAssistance::Services::ApplicationService.new(application_id: params[:id])
      @application = service.copy!
      redirect_to edit_application_path(@application)
    end

    def help_paying_coverage; end

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

    def application_year_selection
      @application = FinancialAssistance::Application.where(id: params[:id], family_id: get_current_person.financial_assistance_identifier).first
      save_faa_bookmark(request.original_url)
      set_admin_bookmark_url
      render layout: 'financial_assistance'
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
      @application.calculate_total_net_income_for_applicants
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
      unless current_user.has_hbx_staff_role?
        flash[:error] = 'You are not authorized to access'
        redirect_to applications_path
        return
      end

      @application = FinancialAssistance::Application.where(id: params['id']).first

      if @application.nil? || @application.is_draft?
        redirect_to applications_path
      else
        redirect_to applications_path unless @application.family_id == get_current_person.financial_assistance_identifier

        @applicants = @application.active_applicants
        @all_relationships = @application.relationships
        @demographic_hash = {}
        @income_coverage_hash = {}

        @applicants.each do |applicant|
          file = if FinancialAssistanceRegistry[:has_enrolled_health_coverage].setting(:currently_enrolled).item
                   File.read("./components/financial_assistance/app/views/financial_assistance/applications/raw_application.yml.erb")
                 else
                   File.read("./components/financial_assistance/app/views/financial_assistance/applications/raw_application_hra.yml.erb")
                 end
          application_hash = YAML.safe_load(ERB.new(file).result(binding))
          @demographic_hash[applicant.id] = application_hash[0]["demographics"]
          application_hash[0]["demographics"]["ADDRESSES"] = generate_address_hash(applicant)
          application_hash[1]["financial_assistance_info"]["INCOME"] = generate_income_hash(applicant)
          @income_coverage_hash[applicant.id] = application_hash[1]["financial_assistance_info"]
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
      send_file(
        FinancialAssistance::Engine.root.join(
          FinancialAssistanceRegistry[:ivl_application_checklist].setting(:file_location).item.to_s
        ), :disposition => "inline", :type => "application/pdf"
      )
    end

    private

    def haven_determination_is_enabled?
      FinancialAssistanceRegistry.feature_enabled?(:haven_determination)
    end

    def medicaid_gateway_determination_is_enabled?
      FinancialAssistanceRegistry.feature_enabled?(:medicaid_gateway_determination)
    end

    def determination_request_class
      return FinancialAssistance::Operations::Application::RequestDetermination if haven_determination_is_enabled?
      # TODO: This beelow line will cause failures
      return FinancialAssistance::Operations::Applications::MedicaidGateway::RequestEligibilityDetermination if medicaid_gateway_determination_is_enabled?
    end

    def init_cfl_service
      @cfl_service = ::FinancialAssistance::Services::ConditionalFieldsLookupService.new
    end

    def check_eligibility
      call_service
      return if params['action'] == "get_help_paying_coverage_response"
      [(flash[:error] = helpers.l10n(helpers.decode_msg(@message))), (redirect_to applications_path)] unless @assistance_status
    end

    def call_service
      if FinancialAssistanceRegistry.feature_enabled?(:aceds_curam)
        person = FinancialAssistance::Factories::AssistanceFactory.new(@person)
        @assistance_status, @message = person.search_existing_assistance
      else
        @assistance_status = true
        @message = nil
      end
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

    def check_citizen_immigration_status?(applicant)
      applicant.naturalized_citizen.present? || applicant.eligible_immigration_status.present?
    end

    def generate_income_hash(applicant)
      income_hash = {
        "Does this person have income from an employer (wages, tips, bonuses, etc.) in #{@application.assistance_year}?" => human_boolean(applicant.has_job_income),
        "jobs" => generate_employment_hash(applicant.incomes.jobs),
        "Does this person expect to receive self-employment income in #{@application.assistance_year}? *" => human_boolean(applicant.has_self_employment_income)
      }
      income_hash.merge!("Did this person receive unemployment income at any point in #{@application.assistance_year}? *" => human_boolean(applicant.has_unemployment_income)) if FinancialAssistanceRegistry.feature_enabled?(:unemployment_income)
      income_hash.merge!("Does this person expect to have income from other sources in #{@application.assistance_year}? *" => human_boolean(applicant.has_other_income))
      income_hash
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

    def generate_address_hash(applicant)
      addresses_hash = {}
      applicant.addresses.each do |address|
        addresses_hash["#{address.kind}_address"] = {
          "ADDRESS LINE 1" => address.address_1,
          "ADDRESS LINE 2" => address.address_2,
          "CITY" => address.city,
          "ZIP" => address.zip,
          "STATE" => address.state
        }
      end
      addresses_hash
    end

    def human_boolean(value)
      if value == true
        'Yes'
      elsif value == false
        'No'
      elsif value.nil?
        'N/A'
      else
        value
      end
    end
  end
end
