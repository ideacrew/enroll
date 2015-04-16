class Consumer::EmployeeRolesController < ApplicationController

  def welcome
  end

  def search
    @person = Forms::ConsumerIdentity.new
  end

  def new
    @person = Person.new
  end

end
