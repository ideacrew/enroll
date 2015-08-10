class Consumer::EmployeeRolesController < ApplicationController
  before_action :check_employee_role, only: [:new, :welcome]

  def welcome
  end

  def search
    @person = Forms::EmployeeCandidate.new
    respond_to do |format|
      format.html
    end
  end

  def match
    @employee_candidate = Forms::EmployeeCandidate.new(params.require(:person).merge({user_id: current_user.id}))
    @person = @employee_candidate
    if @employee_candidate.valid?
      found_census_employees = @employee_candidate.match_census_employees
      if found_census_employees.empty?
        respond_to do |format|
          format.html { render 'no_match' }
        end
      else
        @employment_relationships = Factories::EmploymentRelationshipFactory.build(@employee_candidate, found_census_employees.first)
        respond_to do |format|
          format.html { render 'match' }
        end
      end
    else
      respond_to do |format|
        format.html { render 'search' }
      end
    end
  end

  def create
    @employment_relationship = Forms::EmploymentRelationship.new(params.require(:employment_relationship))
    @employee_role, @family = Factories::EnrollmentFactory.construct_employee_role(current_user, @employment_relationship.census_employee, @employment_relationship)
    if @employee_role.present? && @employee_role.try(:census_employee).try(:employee_role_linked?)
      @person = Forms::EmployeeRole.new(@employee_role.person, @employee_role)
      build_nested_models
      respond_to do |format|
        format.html { redirect_to :action => "edit", :id => @employee_role.id }
      end
    else
      respond_to do |format|
        format.html { redirect_to :back, alert: "You can not enroll as another employee"}
      end
    end
  end

  def edit
    @employee_role = EmployeeRole.find(params.require(:id))
    @person = Forms::EmployeeRole.new(current_user.person, @employee_role)
    @person.addresses << @employee_role.new_census_employee.address if @employee_role.new_census_employee.address.present?
    @family = @person.primary_family
    build_nested_models
  end

  def update
    save_and_exit =  params['exit_after_method'] == 'true'
    person = Person.find(params.require(:id))
    object_params = params.require(:person).permit(*person_parameters_list)
    @employee_role = person.employee_roles.detect { |emp_role| emp_role.id.to_s == object_params[:employee_role_id].to_s }
    @person = Forms::EmployeeRole.new(person, @employee_role)
    if @person.update_attributes(object_params)
      if save_and_exit
        respond_to do |format|
          format.html {redirect_to destroy_user_session_path}
        end
      else
        respond_to do |format|
          format.html { redirect_to consumer_employee_dependents_path(employee_role_id: @employee_role.id) }
        end
      end
    else
      if save_and_exit
        respond_to do |format|
          format.html {redirect_to destroy_user_session_path}
        end
      else
        build_nested_models
        respond_to do |format|
          format.html { render "edit" }
        end
      end
    end
  end

  def new_message_to_broker
    @person = current_user.person
    @family = @person.primary_family
    @hbx_enrollment = (@family.latest_household.try(:hbx_enrollments).active || []).last
    @employee_role = @person.employee_roles.first
    @employer_profile = @employee_role.employer_profile
    @broker_agency_accounts = @employer_profile.broker_agency_accounts
    @broker = @broker_agency_accounts.first.writing_agent
  end

  def send_message_to_broker
    @person = current_user.person
    @employee_role = @person.employee_roles.first
    @employer_profile = @employee_role.employer_profile
    @broker_agency_accounts = @employer_profile.broker_agency_accounts
    @broker = @broker_agency_accounts.first.writing_agent
    UserMailer.message_to_broker(@person, @broker, params).deliver_now
    redirect_to insured_plan_shopping_path(:id => params[:hbx_enrollment_id])
  end

  def build_nested_models
    ["home","mobile","work","fax"].each do |kind|
      @person.phones.build(kind: kind) if @person.phones.select{|phone| phone.kind == kind}.blank?
    end

    Address::KINDS.each do |kind|
      @person.addresses.build(kind: kind) if @person.addresses.select{|address| address.kind.to_s.downcase == kind}.blank?
    end

    ["home","work"].each do |kind|
      @person.emails.build(kind: kind) if @person.emails.select{|email| email.kind == kind}.blank?
    end
  end

  def person_parameters_list
    [
      :employee_role_id,
      { :addresses_attributes => [:kind, :address_1, :address_2, :city, :state, :zip] },
      { :phones_attributes => [:kind, :full_phone_number] },
      { :email_attributes => [:kind, :address] },
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
