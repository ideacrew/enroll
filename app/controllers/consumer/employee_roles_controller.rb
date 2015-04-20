class Consumer::EmployeeRolesController < ApplicationController
  def welcome
  end

  def search
    @person = Forms::ConsumerIdentity.new
    respond_to do |format|
      format.html
      format.js
    end
  end

  def match
    @consumer_identity = Forms::ConsumerIdentity.new(params.require(:person))
    service = Services::EmployeeSignupMatch.new
    if @consumer_identity.valid?
      found_information = service.call(@consumer_identity)
      if found_information.nil?
        @person = @consumer_identity
        respond_to do |format|
          format.js { render 'no_match' }
          format.html { render 'no_match' }
        end
      else
        @census_employee, @person = found_information
        @census_family = @census_employee.employee_family
        @benefit_group = @census_family.benefit_group
        @employer_profile = @census_family.employer_profile
        @effective_on = @benefit_group.effective_on_for(@census_employee.hired_on)
        respond_to do |format|
          format.js { render 'match' }
          format.html { render 'match' }
        end
      end
    else
      @person = @consumer_identity
      respond_to do |format|
        format.js { render 'search' }
        format.html { render 'search' }
      end
    end
  end
end
