class Consumer::EmployeeDependentsController < ApplicationController
  def index
    @family = current_user.primary_family
  end
end
