class Employers::FamilyController < ApplicationController

  before_filter :find_employer
  before_filter :find_family, only: [:destroy, :show]

  def new
    @family = build_family
  end

  def create
    params.permit!
    @family = EmployerCensus::EmployeeFamily.new
    @family.attributes = params["employer_census_employee_family"]
    @employer_profile.employee_families << @family
    if @employer_profile.save
      flash.notice = "Employer Census Family is successfully created."
      redirect_to employers_employer_profiles_path(@employer_profile)
    else
      render action: "new"
    end
  end

  def destroy
    @family.destroy
    flash.notice = "Successfully Deleted Employer Census Family."
    redirect_to employers_employer_profiles_path(@employer_profile)
  end

  def show
  end

  private

  def find_employer
    @employer_profile = EmployerProfile.find params["employer_profile_id"]
  end

  def find_family
    @family = @employer_profile.employee_families.where(id: params["id"]).to_a.first
  end

  def build_family
    family = EmployerCensus::EmployeeFamily.new
    family.build_census_employee
    family.build_census_employee.build_address
    family.census_dependents.build
    family
  end

end