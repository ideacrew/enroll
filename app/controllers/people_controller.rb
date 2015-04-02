require 'factories/enrollment_factory'
# require 'plans_parser'

class PeopleController < ApplicationController

  def new
    @person = Person.new
    build_nested_models
    # render action: "new", layout: "form"
  end

  # Uses identifying information to return single pre-existing Person instance if already in DB
  def match_person
    
    @person = Person.new(person_params)

    matched_person = Person.match_by_id_info(@person)
    
    if matched_person.blank?
      # Preexisting Person not found, create new instance and return to complete form entry
      respond_to do |format|
        format.json { render json: { person: @person, matched: false}, status: :ok, location: @person }
      end
    else
      # Matched Person, autofill form with found attributes
      respond_to do |format|
        @person = matched_person.first
        build_nested_models
        format.json { render json: { person: @person, matched: true}, status: :ok, location: @person, matched: true }
      end
    end
  end

  # Uses identifying information to return one or more for matches in employer census
  def match_employer
  end
  
  def person_lading
    @person = Person.find(params[:person_id])
    @employer = Organization.find(params[:organization_id])
    employee_family = Organization.find(@employer.id).employee_family_details(@person)
    @employee = employee_family.census_employee
    build_nested_models
  end
  
  def link_employer
  end
  
  def get_employer
    @person = Person.find(params[:id])
    @employer_profile= EmployerProfile.find_all_by_person(@person).first
    
    respond_to do |format|
      format.js {}
    end
  end
  
  def person_confirm
    @person = Person.find(params[:person_id])
    if params[:employer_id].to_i != 0
      @employer = Employer.find(params[:employer_id])
      #@employee = Employer
      employee_family = Employer.where(:"id" => @employer.id).where(:"employee_families.employee.ssn" => @person.ssn).last.employee_families.last
      @coverage = employee_family.dependents.present? ? "Individual + Family" : "Individual"
      @coverage_flag = "I"
    else
      @employee = @person
    end
    respond_to do |format|
      format.js {}
    end
  end
  
  def plan_details
    #add_employee_role
  end
  
  def dependent_details
    add_employee_role
    @employer_profile = @employee_role.employer_profile
    @employer = @employer_profile.organization
    @person = @employee_role.person
    @employee = @employer_profile.find_employee_by_person(@person)
    # employee_family = Organization.find(@employer.id).employee_family_details(@person)
    # @employee = employee_family.census_employee
    # build_nested_models
  end
  
  def add_employee_role
    @person = Person.find(params[:person_id])
    @employer_profile = Organization.find(params[:organization_id]).employer_profile    
    employer_census_family = @employer_profile.linkable_employee_family_by_person(@person)

    #calling add_employee_role when linkable employee family present
    if employer_census_family.present? && employer_census_family.person.present?
      enroll_parms = {}
      enroll_parms[:user] = current_user
      enroll_parms[:employer_profile] = @employer_profile
      enroll_parms[:ssn] = @person.ssn
      enroll_parms[:last_name] = @person.last_name
      enroll_parms[:first_name] = @person.first_name
      enroll_parms[:gender] = @person.gender
      enroll_parms[:dob] = @person.dob
      enroll_parms[:name_sfx] = @person.name_sfx
      enroll_parms[:name_pfx] = @person.name_pfx
      enroll_parms[:hired_on] = params[:hired_on]

      @employee_role, @family = EnrollmentFactory.add_employee_role(enroll_parms)
    else
      @employee_role = @person.employee_roles.first
    end
    
  end
  
  def add_dependents
    @person = Person.find(params[:person_id])
    @employer = Organization.find(params[:organization_id])
    employee_family = Organization.find(@employer.id).employee_family_details(@person)
    @employee = employee_family.census_employee
    @dependent = EmployerCensus::Dependent.new
  end
  
  def save_dependents
    new_dependent = EmployerCensus::Dependent.new(dependent_params)
    @person = Person.find(params[:person])
    @employer = Organization.find(params[:employer])
    employee_family = Organization.find(@employer.id).employee_family_details(@person)
    @dependent = employee_family.census_dependents.where(id: new_dependent.id).first
    if @dependent.blank?
      @dependent = employee_family.census_dependents.build(params[:employer_census_dependent])
      respond_to do |format|
        if @dependent.save
          format.js { flash.now[:notice] = "Family Member Added." }
        else
          format.js { flash.now[:error_msg] = "Error in Family Member Addition." } 
        end
      end
    else
      if @dependent.update_attributes(params[:employer_census_dependent])
        respond_to do |format|
          format.js { flash.now[:notice] = "Family Member Updated." } 
        end
      else
        respond_to do |format|
          format.js { flash.now[:error_msg] = "Error in Family Member Edit." } 
        end
      end
    end
  end
  
  def remove_dependents
    @person = Person.find(params[:person_id])
    @employer = Organization.find(params[:organization_id])
    employee_family = Organization.find(@employer.id).employee_family_details(@person)
    @dependent = employee_family.census_dependents.where(_id: params[:id]).first
    if !@dependent.nil?
      @family_member_id = @dependent._id
      @dependent.destroy
    else
      @family_member_id = params[:id]
    end
    respond_to do |format|
      format.js { flash.now[:notice] = "Family Member Removed" } 
    end
  end
  
  def person_landing
    @person = Person.find(params[:person_id])
    if params[:organization_id].to_i != 0
      @employer = Organization.find(params[:organization_id])
      employee_family = Organization.find(@employer.id).employee_family_details(@person)
      @employee = employee_family.census_employee
    else
      @employee = @person
    end
    build_nested_models
    respond_to do |format|
      format.js {}
      format.html {}
    end
  end

  def update
    @person = Person.find(params[:id])
    @person.updated_by = current_user.email unless current_user.nil?
    santize_person_params
    respond_to do |format|
      if @person.update_attributes(person_params)
        format.html { redirect_to @person, notice: 'Person was successfully updated.' }
        format.json { head :no_content }
      else
        build_nested_models
        format.html { render action: "show" }
        format.json { render json: @person.errors, status: :unprocessable_entity }
      end
    end
  end

  def create
    santize_person_params
    @person = Person.find_or_initialize_by(ssn: params[:person][:ssn])

    # person_params
    respond_to do |format|
      if @person.update_attributes(person_params)
        format.html { redirect_to @person, notice: 'Person was successfully created.' }
        # format.html { redirect_to person_landing_people_path(organization_id: @person.organization_id, person_id: @person), notice: 'Person was successfully created.' }

        format.json { render json: @person, status: :created, location: @person }
      else
        build_nested_models
        format.html { render action: "new" }
        format.json { render json: @person.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit
    @person = Person.find(params[:id])
    build_nested_models
  end
  
   def show
    @person = Person.find(params[:id])
    @employer_profile= EmployerProfile.find_all_by_person(@person).first

    build_nested_models
  end

  def plans_converson
    # file_contents = File.read(Rails.root.join('public/xml/AE_DC_SG_73987_Benefits_ON_v2.xml'))
    # @rows = []
    # PlansParser.parse(file_contents).each do |plan|
    # row = []
    #   if Benefit::PLAN_BENEFITS.include?(plan.visit_type.squish)
    #     @rows << plan
    #   end
    # end
  end
  
  def select_plan
    
  end
  

private
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
  
  def santize_person_params
    person_params["addresses_attributes"].each do |key, address|
      if address["city"].blank? && address["zip"].blank? && address["address_1"].blank?
        person_params["addresses_attributes"].delete("#{key}")
      end
    end
    
    person_params["phones_attributes"].each do |key, phone|
      if phone["full_phone_number"].blank? 
        person_params["phones_attributes"].delete("#{key}")
      end
    end
   
    person_params["emails_attributes"].each do |key, phone|
      if phone["address"].blank? 
        person_params["emails_attributes"].delete("#{key}")
      end
    end  
  end
  
  
  def person_params
    params.require(:person).permit!
  end
  
  def dependent_params
    params.require(:employer_census_dependent).permit!
  end

end
