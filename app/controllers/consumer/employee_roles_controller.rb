class Consumer::EmployeeRolesController < ApplicationController
  before_action :check_employee_role, only: [:new, :welcome]

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
    @employee_role, @family = Factories::EnrollmentFactory.construct_employee_role(current_user, @employment_relationship.employee_family, @employment_relationship)
    @person = Forms::EmployeeRole.new(@employee_role.person, @employee_role)
    build_nested_models
    respond_to do |format|
      format.js { render "edit" }
      format.html { render "edit" }
    end
  end

  def update
    #@person = Forms::EmployeeRole.find(params.require(:id))
    person = Person.find(params.require(:id))
    object_params = params.require(:person).permit(*person_parameters_list)
    @employee_role = person.employee_roles.detect { |emp_role| emp_role.id.to_s == object_params[:employee_role_id].to_s }
    @person = Forms::EmployeeRole.new(person, @employee_role)
    if @person.update_attributes(object_params)
      respond_to do |format|
        format.html { render "dependent_details" }
        format.js { render "dependent_details" }
      end
    else
      @employer_profile = @person.employer_profile
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

  private
    def check_employee_role
      if current_user.has_employee_role?
        redirect_to home_consumer_profiles_path
      end
    end
end
