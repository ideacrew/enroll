class EmployeeRolesController < ApplicationController

  def new
    @form = Forms::ConsumerIdentity.new
  end

  def create
    @form = Forms::ConsumerIdentity.new(params[:consumer_identity])
    if @form.valid?
      # Substitute for factory?
      @service = Services::EmployeeSignupMatch.new
      @employee_role = @service.call(@form)
      # The employee role has been found and linked - let me perform edits
      if @employee_role
        render 'edit'
      else
        render 'no_match'
      end
    else
      render 'new'
    end
  end
end
