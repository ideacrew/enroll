class FinancialAssistance::ApplicationsController < ApplicationController
  include UIHelpers::WorkflowController

  def index
    @existing_applications = household = Family.find_by(person_id: current_user.person).active_household.applications

    # view needs to show existing steps if any exist
    # show link to new application (new_financial_assistance_applcations_path)
  end

  def new
    render 'workflow/step'

    # renders out first step
  end

  def step
    attributes = params[:attributes].merge(workflow: { current_step: @current_step.to_i + 1 })
    @model.attributes = survey_params(attributes)
    @model.save!

    render 'workflow/step'

    # renders subsequent steps, needs id to find current_step
    # form_for will need to be updated to handle ids in the url generation
  end

  private
  def survey_params(attributes)
    attributes.permit!
  end

  def find
    Family.find_by(person_id: current_user.person).active_household.applications.find(params[:id]) if params.key?(:id)
  end

  def create
    Family.find_by(person_id: current_user.person).active_household.applications.new
  end
end
