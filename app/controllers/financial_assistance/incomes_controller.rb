 class FinancialAssistance::IncomesController < ApplicationController

  include UIHelpers::WorkflowController

  before_filter :find_application_and_applicant
  #skip_before_action :verify_authenticity_token
  def new
    @model = FinancialAssistance::Application.find(params[:application_id]).applicants.find(params[:applicant_id]).incomes.build
    load_steps
    current_step
    render 'workflow/step'
  end

  def step
    model_name = @model.class.to_s.split('::').last.downcase
    model_params = params[model_name]
    @model.update_attributes!(permit_params(model_params)) if model_params.present?

    if params.key?(:step)
      @model.workflow = { current_step: @current_step.to_i }
    else
      @model.workflow = { current_step: @current_step.to_i + 1 }
      @current_step = @current_step.next_step
    end

    @model.save!

    if params[:commit] == "Finish"
      flash[:notice] = 'Income Info Added.'
      redirect_to edit_financial_assistance_application_applicant_path(@application, @applicant)
    else
      render 'workflow/step'
    end
  end

  private
  def find_application_and_applicant
    @application = FinancialAssistance::Application.find(params[:application_id])
    @applicant = @application.applicants.find(params[:applicant_id])
  end

  def create
    FinancialAssistance::Application.find(params[:application_id]).applicants.find(params[:applicant_id]).incomes.build
  end

  def permit_params(attributes)
    attributes.permit!
  end

  def find
    begin
      FinancialAssistance::Application.find(params[:application_id]).applicants.find(params[:applicant_id]).incomes.find(params[:id])
    rescue
      nil
    end
  end
end
