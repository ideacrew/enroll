class FinancialAssistance::ApplicationsController < ApplicationController
  include UIHelpers::WorkflowController
  #skip_before_filter :verify_authenticity_token, :only => :step

  def index
    @applications = current_user.person.primary_family.applications
    # view needs to show existing steps if any exist
    # show link to new application (new_financial_assistance_applcations_path)
  end

  def new
    # /financial_assistance/applications/new
    # basically just shows a button to start a new application
    # posts to create
    #@family = Family.find(params[:family_id])
    #@family_member = @family.family_members.find(params[:family_member_id])
    @application = FinancialAssistance::Application.new
  end

  def create
    # new POSTs to here
    # needs to create a new application, populate with existing information,
    # like applications from existing families
    # redirects to the edit (or show) view
    @application = current_user.person.primary_family.applications.new
    @application.applicants = @current_user.person.primary_family.family_members.map do |family_member|
      FinancialAssistance::Applicant.new family_member_id: family_member.id
    end
    @application.save!
    redirect_to edit_financial_assistance_application_path(@application)
  end

  def edit
    # displays in progress application
    @family = current_user.person.primary_family
    @application = FinancialAssistance::Application.find(params[:id])
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
     else
       render 'workflow/step'
    end
  end

  private

  def hash_to_param param_hash
    ActionController::Parameters.new(param_hash)
  end

  def permit_params(attributes)
    attributes.permit!
  end

  def update_params(model_key, params_instance, params)
    @model.attributes.merge!("workflow" => {"current_step" => @current_step.to_i + 1 }) # Add workflow params
    params_instance.first.last.merge!(family_member_id: params[:member_id]) if model_key == "applicants_attributes" # Add foreign key reference to appplicant
  end

  def find
    # TODO:Find the latest application in-progress
    @application = current_user.person.primary_family.applications.find(params[:id]) if params.key?(:id)
  end
end