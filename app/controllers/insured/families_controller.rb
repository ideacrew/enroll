class Insured::FamiliesController < FamiliesController
  
  def home
    # @family_members = @family.active_family_members if @family.present?
    # @employee_roles = @person.employee_roles
    # @employer_profile = @employee_roles.first.employer_profile if @employee_roles.any?
    # @current_plan_year = @employer_profile.latest_plan_year if @employer_profile.present?
    # @benefit_groups = @current_plan_year.benefit_groups if @current_plan_year.present?
    # @benefit_group = @current_plan_year.benefit_groups.first if @current_plan_year.present?
    @qualifying_life_events = QualifyingLifeEventKind.all
    @hbx_enrollments = @family.try(:latest_household).try(:hbx_enrollments).active || []
    @employee_role = @person.employee_roles.try(:first)

    respond_to do |format|
      format.html
      format.js
    end
  end 
end
