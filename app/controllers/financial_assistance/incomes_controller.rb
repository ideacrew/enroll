class FinancialAssistance::IncomesController < ApplicationController
  include UIHelpers::WorkflowController

  before_filter :find_applicant


  def edit
  	binding.pry
  	@model = @application.applicants.find(params[:id])
  	load_steps
  	current_step
  end

  private
  def find_application
  	@applicant = FinancialAssistance::Application.find(params[:application_id]).where(applicant_id: params[:applicant_id])
  end
end