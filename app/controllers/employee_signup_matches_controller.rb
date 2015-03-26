class EmployeeSignupMatchesController < ApplicationController

  def new
    @form = Forms::ConsumerIdentity.new
  end

  def create
    @form = Forms::ConsumerIdentity.new(params[:consumer_identity])
    if @form.valid?
      @service = Services::EmployeeSignupMatch.new
      @employee_signup = @service.call(@form)
      # render the correct action here for the
      # 'found person' form
      if @employee_signup
        render 'employee_signups/new'
      else
        render 'no_match'
      end
    else
      render 'new'
    end
  end
end
