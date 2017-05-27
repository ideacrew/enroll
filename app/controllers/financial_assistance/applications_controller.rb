class FinancialAssistance::ApplicationsController < ApplicationController
  include UIHelpers::WorkflowController
  #skip_before_filter :verify_authenticity_token, :only => :step

  def index
    @existing_applications = Family.find_by(person_id: current_user.person).applications

    # view needs to show existing steps if any exist
    # show link to new application (new_financial_assistance_applcations_path)
  end

  def new
    @family = Family.find(params[:family_id])
    @family_member = @family.family_members.find(params[:family_member_id])
    render 'workflow/step'
    # renders out first step
  end

  def step
    attributes = []
    params.each {|param| attributes << {param.first => param.second} if param.first.include?"_attributes"}

    attributes.each do  |attribute_params|
      attribute_params.each do |model_key, params_instance|
        update_params(model_key, params_instance, params)
        @model.update_attributes!(survey_params(hash_to_param(attribute_params)))
      end
    end

    if params.key?(:step)
      @model.workflow = { current_step: @current_step.to_i }
    else
      @model.workflow = { current_step: @current_step.to_i + 1 }
      @current_step = @current_step.next_step
    end
    @model.save!
    render 'workflow/step'
  end

  private

  def hash_to_param param_hash
    ActionController::Parameters.new(param_hash)
  end

  def survey_params(attributes)
    attributes.permit!
  end

  def update_params(model_key, params_instance, params)
    binding.pry
    @family = Family.find(params[:family_id]) if params[:family_id].present?
    @family_member = @family.family_members.find(params[:family_member_id]) if params[:family_member_id].present?
    @model.attributes.merge!("workflow" => {"current_step" => @current_step.to_i + 1 }) # Add workflow params
    params_instance.first.last.merge!(family_member_id: @family_member.id) if model_key == "applicants_attributes" # Add foreign key reference to appplicant
  end

  def find
    #Family.find_by(person_id: current_user.person).applications.find(params[:id]) if params.key?(:id)
    current_user.person.primary_family.applications.find(params[:id]) if params.key?(:id)
    # Can you have two active application ?
    # Which one does it pick on “Add Info?”
    #TODO: Baaed on the above find the application that is currently in progress. application_in_progress?
  end

  def create
    current_user.person.primary_family.applications.new
  end

end
