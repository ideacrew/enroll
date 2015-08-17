class Consumer::ConsumerRolesController < ApplicationController

  def new
    @person = current_user.build_person
    build_nested_models
  end

  def create
    @consumer_role = Factories::EnrollmentFactory.construct_consumer_role(params.permit!, current_user)
    @person = @consumer_role.person
    respond_to do |format|
      format.html { redirect_to :action => "edit", :id => @consumer_role.id }
    end
  end

  def edit
    @consumer_role = ConsumerRole.find(params.require(:id))
    @person = @consumer_role.person
    build_nested_models
  end

  def update
    @consumer_role = ConsumerRole.find(params.require(:id))
    @person = @consumer_role.person
    @person.addresses = []
    @person.phones = []
    @person.emails = []
    if @person.update_attributes(params.require(:person).permit(*person_parameters_list))
      redirect_to new_insured_interactive_identity_verifications_path
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
      { :email_attributes => [:kind, :address] },
      :first_name,
      :last_name,
      :middle_name,
      :name_pfx,
      :name_sfx,
      :date_of_birth,
      :ssn,
      :gender,
      :language_code,
      :is_incarcerated,
      :race,
      :is_tobacco_user,
      :is_consumer_role,
      :ethnicity
    ]
  end

  def build_nested_models
    Phone::KINDS.delete_if{|kind| kind == "work"}.each do |kind|
      @person.phones.build(kind: kind) if @person.phones.select{|phone| phone.kind == kind}.blank?
    end

    Address::KINDS.each do |kind|
      @person.addresses.build(kind: kind) if @person.addresses.select{|address| address.kind.to_s.downcase == kind}.blank?
    end

    Email::KINDS.each do |kind|
      @person.emails.build(kind: kind) if @person.emails.select{|email| email.kind == kind}.blank?
    end
  end
end
