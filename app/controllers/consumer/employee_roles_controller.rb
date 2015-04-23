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
    service = Services::EmployeeSignupMatch.new
    if @employee_candidate.valid?
      found_information = service.call(@employee_candidate)
      if found_information.nil?
        @person = @employee_candidate
        respond_to do |format|
          format.js { render 'no_match' }
          format.html { render 'no_match' }
        end
      else
        @census_employee, @person = found_information
        @census_family = @census_employee.employee_family
        @benefit_group = @census_family.benefit_group
        @employer_profile = @census_family.employer_profile
        @effective_on = @benefit_group.effective_on_for(@census_employee.hired_on)
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
    @person = Forms::EmployeeRole.from_parameters(params.require(:person))
    if @person.save
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
        format.html { render "match" }
        format.js { render "match" }
      end
    end
  end

  def update
    @person = Forms::EmployeeRole.find(params.require(:id))
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
        format.html { render "match" }
        format.js { render "match" }
      end
    end
  end
end
