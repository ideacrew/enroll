class EmployeesController < ApplicationController
  def index
  end

  def show
  end

  def new
    @person = Person.new
    build_nested_person_models

    @person.addresses.first.city = "Washington"
    @person.addresses.first.state = "DC"

  end

  def edit
  end

private
  def build_nested_person_models
    @person.addresses.build if @person.addresses.empty?
    @person.phones.build if @person.phones.empty?
    @person.emails.build if @person.emails.empty?
  end

end
