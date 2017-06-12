class FinancialAssistance::PreWorkflowController < ApplicationController
  include NavigationHelper

  def help_paying_coverage
    @selectedTab = "householdInfo"
    @allTabs = NavigationHelper::getAllTabs
    @transaction_id = params[:id]
  end

  def application_checklist
    @person = current_user.person
    family = @person.primary_family
    family.is_applying_for_assistance = params["is_applying_for_assistance"]
    family.save!
    if family.is_applying_for_assistance
      application = family.applications.build(aasm_state: "inprogress")
      application.applicants.build(has_fixed_address: false, tax_filer_kind: "single", family_member_id: family.primary_applicant.id)
      @transaction_id = application.id
      family.save!
    else
      #TODO redirect the user to household info page
      @transaction_id = params[:id]
      redirect_to insured_family_members_path(:consumer_role_id => @person.consumer_role.id)
    end
  end
end
