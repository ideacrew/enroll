class Consumer::ConsumerRolesController < ApplicationController
  before_action :find_consumer_role_and_person, only: [:edit, :update]

  def search
    @person = Forms::EmployeeCandidate.new
    respond_to do |format|
      format.html
    end
  end

  def match
    @person_params = params.require(:person).merge({user_id: current_user.id})
    @employee_candidate = Forms::EmployeeCandidate.new(@person_params)
    @person = @employee_candidate
    respond_to do |format|
      if @employee_candidate.valid?
        found_person = @employee_candidate.match_person
        if found_person.present?
          format.html { render 'match' }
        else
          format.html { render 'no_match' }
        end
      else
        format.html { render 'search' }
      end
    end
  end

  def new
    @person = current_user.build_person
    build_nested_models
  end

  def create
    @consumer_role = Factories::EnrollmentFactory.construct_consumer_role(params.permit!, actual_user)
    @person = @consumer_role.person
    session[:person_id] = @person.id
    respond_to do |format|
      format.html { redirect_to :action => "edit", :id => @consumer_role.id }
    end
  end

  def edit
    build_nested_models
  end

  def update
    @person.addresses = []
    @person.phones = []
    @person.emails = []
    if @person.update_attributes(params.require(:person).permit(*person_parameters_list))
      redirect_to new_insured_interactive_identity_verification_path
    else
      build_nested_models
      respond_to do |format|
        format.html { render "edit" }
      end
    end
  end

  private

  def person_parameters_list
    [
      { :addresses_attributes => [:kind, :address_1, :address_2, :city, :state, :zip] },
      { :phones_attributes => [:kind, :full_phone_number] },
      { :emails_attributes => [:kind, :address] },
      :first_name,
      :last_name,
      :middle_name,
      :name_pfx,
      :name_sfx,
      :dob,
      :ssn,
      :gender,
      :language_code,
      :is_incarcerated,
      :is_disabled,
      :race,
      :is_consumer_role,
      :ethnicity,
      :us_citizen,
      :naturalized_citizen,
      :eligible_immigration_status,
      :indian_tribe_member,
      :tribal_id
    ]
  end

  def build_nested_models
    ["home", "mobile"].each do |kind|
      @person.phones.build(kind: kind) if @person.phones.select{|phone| phone.kind == kind}.blank?
    end

    Address::KINDS.each do |kind|
      @person.addresses.build(kind: kind) if @person.addresses.select{|address| address.kind.to_s.downcase == kind}.blank?
    end

    Email::KINDS.each do |kind|
      @person.emails.build(kind: kind) if @person.emails.select{|email| email.kind == kind}.blank?
    end
  end

  def find_consumer_role_and_person
    @consumer_role = ConsumerRole.find(params.require(:id))
    @person = @consumer_role.person
  end
end
