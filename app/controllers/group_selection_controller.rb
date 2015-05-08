class GroupSelectionController < ApplicationController
  def new
    initialize_common_vars
  end

  def create
    initialize_common_vars
    family_member_ids = params.require(:family_member_ids)
    hbx_enrollment = HbxEnrollment.new_from(
      employer_profile: @employee_role.employer_profile,
      coverage_household: @coverage_household,
      benefit_group: find_benefit_group(@employee_role))
    hbx_enrollment.hbx_enrollment_members = hbx_enrollment.hbx_enrollment_members.select do |member|
      family_member_ids.include? member.applicant_id
    end
    hbx_enrollment.save
    organization = @employee_role.employer_profile.organization
    redirect_to select_plan_people_path(person_id: @person, hbx_enrollment_id: hbx_enrollment, organization_id: organization)
  end

  private

  def initialize_common_vars
    person_id = params.require(:person_id)
    emp_role_id = params.require(:employee_role_id)
    @person = Person.find(person_id)
    @family = @person.primary_family
    @employee_role = @person.employee_roles.detect { |emp_role| emp_role.id.to_s == emp_role_id.to_s }
    @coverage_household = @family.active_household.immediate_family_coverage_household
  end

  def find_benefit_group(employee_role)
    employee_role.benefit_group
  end
end
