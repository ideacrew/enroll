class FinancialAssistance::ApplicantsController < ApplicationController
  include UIHelpers::WorkflowController

  before_filter :find_application


  def edit
  	binding.pry
  	@model = @application.applicants.find(params[:id])
  	load_steps
  	current_step
  end

  private
  def find_application
  	@application = FinancialAssistance::Application.find(params[:application_id])
  end
end