class Consumer::EmployeeDependentsController < ApplicationController
  def index
    @family = current_user.primary_family
    @person = current_user.person
  end

  def new
    @person = current_user.person
    @dependent = Forms::EmployeeDependent.new(:family_id => params.require(:family_id))
  end
end
