# frozen_string_literal: true

module FinancialAssistance
  class ApplicationsController < FinancialAssistance::ApplicationController

    before_action :set_current_person

    include ::UIHelpers::WorkflowController
    include Acapi::Notifiers
    require 'securerandom'

    before_action :check_eligibility, only: [:create, :get_help_paying_coverage_response, :copy]
    before_action :init_cfl_service, only: :review_and_submit

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
      render :plain => application.success_status_codes?(application.determination_http_status_code).to_s
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
  end
end
