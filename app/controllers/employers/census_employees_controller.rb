class Employers::CensusEmployeesController < ApplicationController
  before_action :find_employer, only: [:new, :create, :show]
  before_action :find_census_employee, only: [:show]
  before_action :check_plan_year, only: [:new]

  def new
    census_employee_form = Forms::CensusEmployeeForm.new()
    @census_employee = census_employee_form.build_census_employee_params
  end

  def create
    params.require(:census_employee).permit!
    census_employee_form = ::Forms::CensusEmployeeForm.new(params)
    @census_employee = census_employee_form.build_and_assign_attributes
    if @census_employee.save
      redirect_to employers_employer_profile_path(@employer_profile)
    else
      render action: "new"
    end
  end

  def show
  end

  private

  def find_employer
    @employer_profile = EmployerProfile.find(params["employer_profile_id"])
  end

  def find_census_employee
    @census_employee = CensusEmployee.find(params["id"])
  end

  def check_plan_year
    if @employer_profile.plan_years.empty?
      flash[:notice] = "Please create a plan year before you create your first census family."
      redirect_to new_employers_employer_profile_plan_year_path(@employer_profile)
    end
  end

end