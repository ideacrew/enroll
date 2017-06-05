class FinancialAssistance::DeductionsController < ApplicationController
  include UIHelpers::WorkflowController

  before_filter :find_applicant

  def new
    @model = FinancialAssistance::Application.find(params[:application_id]).applicants.find(params[:applicant_id]).deductions.build
    load_steps
    current_step 
    render 'workflow/step'
  end


  def edit
      @model = @applicant.deductions.find(params[:id])
      load_steps
      current_step
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

    if @steps.last_step?(@current_step) && params[model_name].present?
      flash[:notice] = 'Income Info Added.'
      redirect_to edit_financial_assistance_application_path(@application)
    else
      render 'workflow/step'
    end
  end


  private

  def create
    FinancialAssistance::Application.find(params[:application_id]).applicants.find(params[:applicant_id]).deductions.build
  end

  def find_applicant
      @application = FinancialAssistance::Application.find(params[:application_id])
  end

  def permit_params(attributes)
    attributes.permit!
  end

  def find
    begin
      FinancialAssistance::Application.find(params[:application_id]).applicants.find(params[:applicant_id]).deductions.find(params[:income_id])
    rescue
      nil
    end
  end
  
end