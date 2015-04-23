class Consumer::EmployeeRolesController < ApplicationController
  def welcome
  end

  def search
    @person = Forms::EmployeeCandidate.new
    respond_to do |format|
      format.html
      format.js
    end
  end

  def match
    @employee_candidate = Forms::EmployeeCandidate.new(params.require(:person))
    @person = @employee_candidate
    if @employee_candidate.valid?
      found_families = EmployerProfile.find_census_families_by_person(@employee_candidate)
      if found_families.empty?
        respond_to do |format|
          format.js { render 'no_match' }
          format.html { render 'no_match' }
        end
      else
        @employment_relationships = Factories::EmploymentRelationshipFactory.build(@employee_candidate, found_families)
        respond_to do |format|
          format.js { render 'match' }
          format.html { render 'match' }
        end
      end
    else
      @person = @employee_candidate
      respond_to do |format|
        format.js { render 'search' }
        format.html { render 'search' }
      end
    end
  end

  def create
    @employment_relationship = Forms::EmploymentRelationship.new(params.require(:employment_relationship))
    @employee_role, @family = EnrollmentFactory.add_employee_role(@employment_relationship, @employment_relationship.employee_family, current_user)
    @person = @employee_role
    @benefit_group = @person.benefit_group
    @census_family = @person.census_family
    @census_employee = @person.census_employee
    @effective_on = @benefit_group.effective_on_for(@census_employee.hired_on)
    respond_to do |format|
      format.js { render "edit" }
      format.html { render "edit" }
    end
  end

  def update
    @person = EmployeeRole.find(params.require(:id))
    if @person.update_attributes(params.require(:person))
      @person.primary_family.households.first.coverage_households.first.coverage_household_members.update(applicant_id: params.require(:id))
      respond_to do |format|
        format.html { render "dependent_details" }
        format.js { render "dependent_details" }
      end
    else
      @employer_profile = @person.employer_profile
      @benefit_group = @person.benefit_group
      @census_family = @person.census_family
      @census_employee = @person.census_employee
      @effective_on = @benefit_group.effective_on_for(@census_employee.hired_on)
      respond_to do |format|
        format.html { render "edit" }
        format.js { render "edit" }
      end
    end
  end
end
