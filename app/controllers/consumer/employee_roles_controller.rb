require 'factories/enrollment_factory'

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
    @employee_role, @family = EnrollmentFactory.construct_employee_role(current_user, @employment_relationship.employee_family, @employment_relationship)
    @person = Forms::EmployeeRole.new(@employee_role.person, @employee_role)
    @benefit_group = @employee_role.benefit_group
    @census_family = @employee_role.census_family
    @employer_profile = @census_family.employer_profile
    @census_employee = @employee_role.census_family.census_employee
    @effective_on = @benefit_group.effective_on_for(@census_employee.hired_on)
    build_nested_models
    respond_to do |format|
      format.js { render "edit" }
      format.html { render "edit" }
    end
  end

  def update
    @person = Forms::EmployeeRole.find(params.require(:id))
    if @person.update_attributes(params.require(:person).permit(*person_parameters_list))
      respond_to do |format|
        format.html { render "dependent_details" }
        format.js { render "dependent_details" }
      end
    else
      @employee_role = @person.employee_role
      @employer_profile = @person.employer_profile
      @benefit_group = @person.benefit_group
      @census_family = @person.census_family
      @census_employee = @person.census_employee
      @effective_on = @benefit_group.effective_on_for(@census_employee.hired_on)
      build_nested_models
      respond_to do |format|
        format.html { render "edit" }
        format.js { render "edit" }
      end
    end
  end

  def build_nested_models
    ["home","mobile","work","fax"].each do |kind|
      @person.phones.build(kind: kind) if @person.phones.select{|phone| phone.kind == kind}.blank?
    end

    Address::KINDS.each do |kind|
      @person.addresses.build(kind: kind) if @person.addresses.select{|address| address.kind == kind}.blank?
    end

    ["home","work"].each do |kind|
      @person.emails.build(kind: kind) if @person.emails.select{|email| email.kind == kind}.blank?
    end
  end

  def person_parameters_list
    [
      :employee_role_id,
      :addresses_attributes,
      :phones_attributes,
      :email_attributes,
      :first_name,
      :last_name,
      :middle_name,
      :name_pfx,
      :name_sfx,
      :date_of_birth,
      :ssn,
      :gender
    ]
  end
end
