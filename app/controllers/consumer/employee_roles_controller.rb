class Consumer::EmployeeRolesController < ApplicationController

  def welcome
  end

  def new
    @person = Person.new
  end

end
