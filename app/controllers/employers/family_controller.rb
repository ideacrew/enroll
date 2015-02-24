class Employers::FamilyController < ApplicationController

  before_filter :find_employer
  before_filter :find_family, only: [:destroy]

  def new
    @family = @employer.build_family
  end

  def create
    params.permit!
    family = EmployerCensus::EmployeeFamily.new
    family.attributes = params["employer_census_employee_family"]
    @employer.employee_families << family
    if @employer.save
      flash.notice = "Employer Census Family is successfully created."
      redirect_to employers_employer_path(@employer)
    else
      render action: "new"
    end
  end

  def destroy
    @family.destroy
    flash.notice = "Successfully Deleted Employer Census Family."
    redirect_to employers_employer_path(@employer)
  end

  private

  def find_employer
    @employer = Employer.find params["employer_id"]
  end

  def find_family
    @family = @employer.employee_families.where(id: params["id"]).to_a.first
  end

end