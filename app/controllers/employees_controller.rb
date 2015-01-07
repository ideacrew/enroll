class EmployeesController < ApplicationController
  def index
  end

  def show
  end

  def new
    @person = Person.new
    @employee = @person.build_employee
  end

  def edit
  end
end
