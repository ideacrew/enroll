class Consumer::EmployeeRolesController < ApplicationController

  def welcome
  end

  def search
    @person = Forms::ConsumerIdentity.new
  end

  def new
    @person = Person.new
  end

  def show
  	@person = Person.find(params[:id])
    build_nested_models
  end

  def edit
  	@person = Person.find(params[:id])
    build_nested_models
  end

  def match
    @consumer_identity = Forms::ConsumerIdentity.new(params.require(:person))
    service = Services::EmployeeSignupMatch.new
    if @consumer_identity.valid?
      found_information = service.call(@consumer_identity)
      if found_information.nil?
        render 'no_match'
      else
        @census_employee, @person = found_information
        @census_family = @census_employee.employee_family
        @benefit_group = @census_family.benefit_group
        @employer_profile = @census_family.employer_profile
        @effective_on = @benefit_group.effective_on_for(@census_employee.hired_on)
        render 'match'
      end
    else
      render 'search'
    end
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

end
