class FinancialAssistance::PreWorkflowController < ApplicationController
  # include NavigationHelper

  def help_paying_coverage
    @transaction_id = params[:id]
  end

  def application_checklist
    family = current_user.person.primary_family
    family.is_applying_for_asistance = params["is_applying_for_assistance"]
    family.save!
    @transaction_id = params[:id]
  end
end