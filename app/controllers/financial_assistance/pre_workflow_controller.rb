class FinancialAssistance::PreWorkflowController < ApplicationController
  # include NavigationHelper

  def help_paying_coverage
    # @selectedTab = "householdInfo"
   #    @selectedStepId = "helpPayingCoverage"
   #    @allTabs = NavigationHelper::getAllTabs
   #    @allSteps = NavigationHelper::getStepsOfTab(@selectedTab)
    @transaction_id = params[:id]
  end

  def application_checklist
    # @selectedTab = "householdInfo"
   #    @selectedStepId = "applicationChecklist"
   #    @allTabs = NavigationHelper::getAllTabs
   #    @allSteps = NavigationHelper::getStepsOfTab(@selectedTab)
    @transaction_id = params[:id]
  end
end