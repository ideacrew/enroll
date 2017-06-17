class FinancialAssistance::DeductionsController < ApplicationController
  include UIHelpers::WorkflowController

  before_filter :find_application_and_applicant

  def new
    @model = FinancialAssistance::Application.find(params[:application_id]).applicants.find(params[:applicant_id]).deductions.build
    load_steps
    current_step
    render 'workflow/step'
  end

  def step
    model_name = @model.class.to_s.split('::').last.downcase
    model_params = params[model_name]

    model_params["start_on"]=Date.strptime(model_params["start_on"].to_s, "%m/%d/%Y") if model_params.present?
    model_params["end_on"]=Date.strptime(model_params["end_on"].to_s, "%m/%d/%Y") if model_params.present?

    @model.update_attributes!(permit_params(model_params)) if model_params.present?

    if params.key?(model_name)
      @model.workflow = { current_step: @current_step.to_i + 1 }
      @current_step = @current_step.next_step
    else
      @model.workflow = { current_step: @current_step.to_i }
    end

    @model.save!

    if params[:commit] == "Finish"
      flash[:notice] = 'Deductions Income Info Added.'
      redirect_to edit_financial_assistance_application_applicant_path(@application, @applicant)

    else
      render 'workflow/step'
    end

  end

  def destroy
    deduction = @applicant.deductions.find(params[:id])
    deduction.destroy!
    flash[:success] = "Deduction deleted - (#{deduction.kind})"
    redirect_to edit_financial_assistance_application_applicant_path(@application, @applicant)
  end

  private
  def find_application_and_applicant
    @application = FinancialAssistance::Application.find(params[:application_id])
    @applicant = @application.applicants.find(params[:applicant_id])
  end

  def create
    FinancialAssistance::Application.find(params[:application_id]).applicants.find(params[:applicant_id]).deductions.build
  end

  def find_application_and_applicant
    @application = FinancialAssistance::Application.find(params[:application_id])
    @applicant = @application.applicants.find(params[:applicant_id])
  end

  def permit_params(attributes)
    attributes.permit!
  end

  def find
    begin
      FinancialAssistance::Application.find(params[:application_id]).applicants.find(params[:applicant_id]).deductions.find(params[:id])
    rescue
      nil
    end
  end
end
