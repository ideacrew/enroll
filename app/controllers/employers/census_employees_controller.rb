class Employers::CensusEmployeesController < ApplicationController
  before_action :find_employer
  before_action :check_plan_year, only: [:new]

  def new
    build_census_employee
  end

  private

  def find_employer
    @employer_profile = EmployerProfile.find(params["employer_profile_id"])
  end

  def check_plan_year
    if @employer_profile.plan_years.empty?
      flash[:notice] = "Please create a plan year before you create your first census family."
      redirect_to new_employers_employer_profile_plan_year_path(@employer_profile)
    end
  end

  def build_census_employee
    @census_employee = CensusEmployee.new
    @census_employee.build_address
    @census_employee.census_dependents.build
    @census_employee.benefit_group_assignments.build
    @census_employee
  end
end