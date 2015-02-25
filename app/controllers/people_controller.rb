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

  def link_employer
  end
  
  def get_employer
    @person = Person.find(params[:id])
    @employers = Employer.find_employee_families_by_person(@person)

    respond_to do |format|
      format.js {}
    end
  end
  
  def person_confirm
    @person = Person.find(params[:person_id])
    if params[:employer_id].to_i != 0
      @employer = Employer.find(params[:employer_id])
      @employee = Employer.where(:"id" => @employer.id).where(:"employee_families.employee.ssn" => @person.ssn).last.employee_families.last.employee
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
  
  def person_landing
    @person = Person.find(params[:person_id])
    if params[:employer_id].to_i != 0
      @employer = Employer.find(params[:employer_id])
      @employee = Employer.where(:"id" => @employer.id).where(:"employee_families.employee.ssn" => @person.ssn).last.employee_families.last.employee
    else
      @employee = @person
    end
    build_nested_models
    respond_to do |format|
      format.js {}
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
    @person = Person.new(person_params)
    respond_to do |format|
      if @person.save
        format.html { redirect_to @person, notice: 'Person was successfully created.' }
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
    build_nested_models
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

end
