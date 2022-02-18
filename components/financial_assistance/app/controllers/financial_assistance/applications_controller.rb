# frozen_string_literal: true

module FinancialAssistance
  # IAP application controller
  class ApplicationsController < FinancialAssistance::ApplicationController

    before_action :set_current_person
    before_action :find_application, :except => [:index, :new, :copy, :uqhp_flow, :review, :raw_application, :checklist_pdf]

    include ActionView::Helpers::SanitizeHelper
    include ::UIHelpers::WorkflowController
    include Acapi::Notifiers
    include FinancialAssistance::L10nHelper
    require 'securerandom'

    before_action :check_eligibility, only: [:create, :get_help_paying_coverage_response, :copy]
    before_action :init_cfl_service, only: [:review_and_submit, :raw_application]

    layout "financial_assistance_nav", only: %i[edit step review_and_submit eligibility_response_error application_publish_error]

    # We should ONLY be getting applications that are associated with PrimaryFamily of Current Person.
    # DO NOT include applications from other families.
    def index
      @applications = ::FinancialAssistance::Application.where(family_id: get_current_person.financial_assistance_identifier)
    end

    def new
      @application = FinancialAssistance::Application.new
    end

    def edit
      save_faa_bookmark(request.original_url)
      set_admin_bookmark_url


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
      @model.attributes = @model.attributes.except(:_id) unless @model.persisted?

      # rubocop:disable Metrics/BlockNesting
      if params.key?(model_name)
        if @model.save
          @current_step = @current_step.next_step if @current_step.next_step.present?
          @model.update_attributes!(workflow: { current_step: @current_step.to_i })
          if params[:commit] == "Submit Application"
            if @application.imported?
              redirect_to application_publish_error_application_path(@application), flash: { error: "Submission Error: Imported Application can't be submitted for Eligibity" }
              return
            end
            if @application.complete? && @application.may_submit?
              @application.submit!
              publish_result = determination_request_class.new.call(application_id: @application.id)
              if publish_result.success?
                redirect_to wait_for_eligibility_response_application_path(@application)
              else
                @application.unsubmit! if @application.may_unsubmit?
                flash_message = case publish_result.failure
                                when Dry::Validation::Result
                                  { error: validation_errors_parser(publish_result.failure) }
                                when Exception
                                  { error: publish_result.failure.message }
                                else
                                  { error: "Submission Error: #{publish_result.failure}" }
                                end
                redirect_to application_publish_error_application_path(@application), flash: flash_message
              end
            else
              redirect_to application_publish_error_application_path(@application), flash: { error: build_error_messages(@model) }
            end
          else
            render 'workflow/step'
          end
        else
          @model.assign_attributes(workflow: { current_step: @current_step.to_i })
          @model.save!(validate: false)
          flash[:error] = build_error_messages(@model).join(", ")
          render 'workflow/step'
        end
      else
        render 'workflow/step'
      end
      # rubocop:enable Metrics/BlockNesting
    end
    # rubocop:enable Metrics/AbcSize

    def copy
      copy_result = ::FinancialAssistance::Operations::Applications::Copy.new.call(application_id: application.id)
      if copy_result.success?
        @application = copy_resultsuccess
        redirect_to edit_application_path(@application)
      else
        flash[:error] = copy_result.failure
        redirect_to applications_path
      end
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
      save_faa_bookmark(request.original_url)
      set_admin_bookmark_url
      render layout: 'financial_assistance'
    end

    def application_checklist
      save_faa_bookmark(request.original_url)
      set_admin_bookmark_url
    end

    def review_and_submit
      save_faa_bookmark(request.original_url)
      set_admin_bookmark_url
      @all_relationships = @application.relationships
      @application.calculate_total_net_income_for_applicants
      @applicants = @application.active_applicants if @application.present?
      flash[:error] = 'Applicant has incomplete information' if @application.incomplete_applicants?

      unless @application.valid_relations?
        redirect_to application_relationships_path(@application)
        flash[:error] = l10n("faa.errors.inconsistent_relationships_error")
      end
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

      @application = FinancialAssistance::Application.where(id: params['id'], family_id: get_current_person.financial_assistance_identifier).first

      if @application.nil? || @application.is_draft?
        redirect_to applications_path
      else

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
      render layout: 'financial_assistance'
    end

    def eligibility_results
      save_faa_bookmark(request.original_url)
      set_admin_bookmark_url
      render layout: (params.keys.include?('cur') ? 'financial_assistance_nav' : 'financial_assistance')
    end

    def application_publish_error
      save_faa_bookmark(request.original_url)
      set_admin_bookmark_url
    end

    def eligibility_response_error
      save_faa_bookmark(request.original_url)
      set_admin_bookmark_url
      redirect_to eligibility_results_application_path(@application.id, cur: 1) if eligibility_results_received?(@application)
      @application.update_attributes(determination_http_status_code: 999) if @application.determination_http_status_code.nil?
      @application.send_failed_response
    end

    def check_eligibility_results_received
      application = find_application
      render :plain => eligibility_results_received?(application).to_s
    end

    def checklist_pdf
      send_file(
        FinancialAssistance::Engine.root.join(
          FinancialAssistanceRegistry[:ivl_application_checklist].setting(:file_location).item.to_s
        ), :disposition => "inline", :type => "application/pdf"
      )
    end

    def update_transfer_requested
      @application = Application.find(params[:id])
      @button_sent_text = l10n("faa.sent_to_external_verification")

      respond_to do |format|
        if @application.update_attributes(transfer_requested: true)
          format.js
        else
          # TODO: respond with HTML on failure???
          format.html
        end
      end
    end

    private

    def eligibility_results_received?(application)
      application.success_status_codes?(application.determination_http_status_code) && application.determined?
    end

    def validation_errors_parser(result)
      result.errors.each_with_object([]) do |error, collect|
        collect << if error.is_a?(Dry::Schema::Message)
                     message = error.path.reduce("The ") do |attribute_message, path|
                       next_element = error.path[(error.path.index(path) + 1)]
                       attribute_message + if next_element.is_a?(Integer)
                                             "#{(next_element + 1).ordinalize} #{path.to_s.humanize.downcase}'s "
                                           elsif path.is_a? Integer
                                             ""
                                           else
                                             "#{path.to_s.humanize.downcase}:"
                                           end
                     end
                     message + " #{error.text}."
                   else
                     error.flatten.flatten.join(',').gsub(",", " ").titleize
                   end
      end
    end

    def build_error_messages(model)
      model.errors.full_messages
    end

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

    def hash_to_param(param_hash)
      ActionController::Parameters.new(param_hash)
    end

    def permit_params(attributes)
      attributes.permit!
    end

    def find
      find_application
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
        strip_tags(l10n('faa.incomes.from_employer', assistance_year: FinancialAssistanceRegistry[:enrollment_dates].setting(:application_year).item.constantize.new.call.value!.to_s)) => human_boolean(applicant.has_job_income),
        "jobs" => generate_employment_hash(applicant.incomes.jobs),
        strip_tags(l10n('faa.incomes.from_self_employment', assistance_year: FinancialAssistanceRegistry[:enrollment_dates].setting(:application_year).item.constantize.new.call.value!.to_s)) => human_boolean(applicant.has_self_employment_income)
      }
      if FinancialAssistanceRegistry.feature_enabled?(:unemployment_income)
        income_hash.merge!(strip_tags(l10n('faa.other_incomes.unemployment',
                                           assistance_year: FinancialAssistanceRegistry[:enrollment_dates].setting(:application_year).item.constantize.new.call.value!.to_s)) => human_boolean(applicant.has_unemployment_income))
      end
      income_hash.merge!(strip_tags(l10n('faa.other_incomes.other_sources',
                                         assistance_year: FinancialAssistanceRegistry[:enrollment_dates].setting(:application_year).item.constantize.new.call.value!.to_s)) => human_boolean(applicant.has_other_income))
      income_hash
    end

    def generate_employment_hash(jobs)
      job_hash = {}
      jobs.each do |job|
        job_hash[job.id] = {
          "Employer Name" => job.employer_name,
          "EMPLOYER ADDRESSS LINE 1" => job&.employer_address&.address_1,
          "EMPLOYER ADDRESSS LINE 2" => job&.employer_address&.address_2,
          "CITY" => job&.employer_address&.city,
          "STATE" => job&.employer_address&.state,
          "ZIP" => job&.employer_address&.zip,
          "EMPLOYER PHONE " => job.employer_phone&.full_phone_number
        }
      end
      job_hash
    end

    def generate_address_hash(applicant)
      addresses_hash = {}
      applicant.addresses.each do |address|
        addresses_hash["#{address.kind}_address"] = {
          "ADDRESS LINE 1" => address&.address_1,
          "ADDRESS LINE 2" => address&.address_2,
          "CITY" => address&.city,
          "ZIP" => address&.zip,
          "STATE" => address&.state,
          "COUNTY" => address&.county
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
