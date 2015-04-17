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
  	# @employer_profile= EmployerProfile.find_all_by_person(@person).first

    # build_nested_models
  end

end
