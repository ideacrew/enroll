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
    @person = Forms::ConsumerIdentity.new(params.require(:person))
    if @person.valid?
      render 'match'
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
