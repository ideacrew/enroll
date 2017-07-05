class FinancialAssistance::ApplicationsController < ApplicationController

  before_action :set_current_person

  include UIHelpers::WorkflowController
  include NavigationHelper
  include Acapi::Notifiers
  require 'securerandom'

  def index
    @family = @person.primary_family
    @applications = @family.applications
  end

  def new
    @application = FinancialAssistance::Application.new
  end

  def create
    @application = @person.primary_family.applications.new
    @application.populate_applicants_for(@person.primary_family)
    @application.save!
    redirect_to edit_financial_assistance_application_path(@application)
  end

  def edit
    @family = @person.primary_family
    @application = FinancialAssistance::Application.find(params[:id])

    render layout: 'financial_assistance'
  end

  def step
    flash[:error] = nil
    model_name = @model.class.to_s.split('::').last.downcase
    model_params = params[model_name]
    @model.clean_conditional_params(model_params) if model_params.present?
    @model.assign_attributes(permit_params(model_params)) if model_params.present?

    if params.key?(model_name)
      if @model.save
        @current_step = @current_step.next_step if @current_step.next_step.present?
        if params[:commit] == "Finish"
          @model.update_attributes!(workflow: { current_step: 1 })
          redirect_to edit_financial_assistance_application_path(@application)
        elsif params[:commit] == "Submit my Application"
          @model.update_attributes!(workflow: { current_step: @current_step.to_i })
          @application.submit! if @application.complete?
          redirect_to eligibility_results_financial_assistance_applications_path
        else
          @model.update_attributes!(workflow: { current_step: @current_step.to_i })
          render 'workflow/step', layout: 'financial_assistance'
        end
      else
        @model.assign_attributes(workflow: { current_step: @current_step.to_i })
        @model.save!(validate: false)
        flash[:error] = build_error_messages(@model)
        render 'workflow/step', layout: 'financial_assistance'
      end
    else
      render 'workflow/step', layout: 'financial_assistance'
    end
  end

  def publish_application(application)
    response_payload = render_to_string "events/financial_assistance_application", :formats => ["xml"], :locals => { :financial_assistance_application => application }
    notify("acapi.info.events.assistance_application.submitted",
              {:correlation_id => SecureRandom.uuid.gsub("-",""),
                :body => response_payload,
                :family_id => application.family_id.to_s,
                :application_id => application._id.to_s})
  end

  def help_paying_coverage
    @transaction_id = params[:id]
  end

  def get_help_paying_coverage_response
    family = @person.primary_family
    family.is_applying_for_assistance = params["is_applying_for_assistance"]
    family.save!
    if family.is_applying_for_assistance
      application = family.applications.build(aasm_state: "draft")
      application.applicants.build(family_member_id: family.primary_applicant.id)
      application.save!
      redirect_to application_checklist_financial_assistance_applications_path
    else
      redirect_to insured_family_members_path(:consumer_role_id => @person.consumer_role.id)
    end
  end

  def application_checklist
  end

  def review_and_submit
    @consumer_role = @person.consumer_role
    @application = @person.primary_family.application_in_progress
    @applicants = @application.applicants

    render layout: 'financial_assistance'
  end

  def wait_for_eligibility_response
  end

  def eligibility_results
  end

  private

  def dummy_data_for_demo(params)
    #Dummy_ED
    @model.update_attributes!(aasm_state: "approved", assistance_year: TimeKeeper.date_of_record.year)
    @model.applicants.each do |applicant|
      applicant.update_attributes!(is_ia_eligible: true)
    end
    @model.tax_households.each do |txh|
      txh.update_attributes!(allocated_aptc: 200.00)
      @model.eligibility_determinations.build(max_aptc: 200.00, csr_percent_as_integer: 73, csr_eligibility_kind: "csr_73", determined_on: TimeKeeper.datetime_of_record - 30.days, determined_at: TimeKeeper.datetime_of_record - 30.days, premium_credit_strategy_kind: "allocated_lump_sum_credit", e_pdc_id: "3110344", source: "Admin", tax_household_id: txh.id).save!
      @model.applicants.second.update_attributes!(is_medicaid_chip_eligible: true) if txh.applicants.count > 1
    end
  end

  def build_error_messages(model)
    model.valid? ? nil : model.errors.messages.first.flatten.flatten.join(',').gsub(",", " ").titleize
  end

  def hash_to_param param_hash
    ActionController::Parameters.new(param_hash)
  end

  def permit_params(attributes)
    attributes.permit!
  end

  def find
    @application = @person.primary_family.applications.find(params[:id]) if params.key?(:id)
  end
end
