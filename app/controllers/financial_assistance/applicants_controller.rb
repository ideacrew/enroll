class FinancialAssistance::ApplicantsController < ApplicationController
  include UIHelpers::WorkflowController

  before_filter :find_application


  def edit
  	@applicant = @application.applicants.find(params[:id])
  end

  private
  def find_application
  	@application = FinancialAssistance::Application.find(params[:application_id])
  end
end
