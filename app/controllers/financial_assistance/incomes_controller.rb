class FinancialAssistance::IncomesController < ApplicationController
  include UIHelpers::WorkflowController

  before_filter :find_application_and_applicant

  def new
    @model = @applicant.incomes.build
    load_steps
    current_step

    render 'workflow/step'
  end

  private
  def find_application_and_applicant
    @application = FinancialAssistance::Application.find(params[:application_id])
    @applicant = @application.applicants.find(params[:applicant_id])
  end
end
