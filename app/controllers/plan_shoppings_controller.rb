class PlanShoppingsController < ApplicationController

  def checkout
    @person = find_person(params[:id])
    @plan = Plan.find(params[:plan_id])
    @organization = find_organization(params[:organization_id])
    @benefit_group = find_benefit_group(@person, @organization)
    @reference_plan = @benefit_group.reference_plan
    @hbx_enrollment = new_hbx_enrollment(@person, @organization, @benefit_group)
    @plan = PlanCostDecorator.new(@plan, @hbx_enrollment, @benefit_group, @reference_plan)
    UserMailer.plan_shopping_completed(current_user, @hbx_enrollment, @plan).deliver_now

    redirect_to person_person_landing_path(@person)
  end

  def find_person(id)
    begin
      Person.find(id)
    rescue
      nil
    end
  end

  def find_organization(id)
    begin
      Organization.find(id)
    rescue
      nil
    end
  end

  def find_benefit_group(person, organization)
    organization.employer_profile.latest_plan_year.benefit_groups.first
    # person.employee_roles.first.benefit_group
  end

  def new_hbx_enrollment(person, organization, benefit_group)
    HbxEnrollment.new_from(employer_profile: organization.employer_profile,
                           coverage_household: person.primary_family.households.first.coverage_households.first,
                           benefit_group: benefit_group)
  end
end
