class FinancialAssistance::ApplicationsController < ApplicationController

  before_action :set_current_person

  include UIHelpers::WorkflowController
  include NavigationHelper

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
    model_name = @model.class.to_s.split('::').last.downcase
    model_params = params[model_name]
    @model.update_attributes!(permit_params(model_params)) if model_params.present?
    if params.key?(model_name)
     @model.workflow = { current_step: @current_step.to_i + 1}
     @current_step = @current_step.next_step
    else
     @model.workflow = { current_step: @current_step.to_i}
    end

    @model.save!
    if params[:commit] == "Finish"
      redirect_to edit_financial_assistance_application_path(@application)
    elsif params[:commit] == "Submit my Application"
      @application.submit! if @application.complete?
      redirect_to eligibility_results_financial_assistance_applications_path
    else
      render 'workflow/step', layout: 'financial_assistance'
    end
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
  end

  def eligibility_results
  end

  private

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
