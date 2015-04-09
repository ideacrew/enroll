class Employers::FamilyController < ApplicationController

  before_action :find_employer
  before_action :set_family_id, only: [:delink]
  before_action :find_family, only: [:destroy, :show, :edit, :update]

  def new
    @family = build_family
  end

  def create
    params.permit!
    @family = EmployerCensus::EmployeeFamily.new
    @family.attributes = params["employer_census_employee_family"]
    @employer_profile.employee_families << @family
    if @employer_profile.save!
      flash.notice = "Employer Census Family is successfully created."
      redirect_to employers_employer_profile_path(@employer_profile)
    else
      render action: "new"
    end
  end

  def edit
    @family.census_employee.build_address unless @family.census_employee.address.present?
    @family.census_dependents.build unless @family.census_dependents.present?
  end

  def update
    if @family.update_attributes(census_employee_params)
      flash.notice = "Employer Census Family is successfully updated."
      redirect_to employers_employer_profile_path(@employer_profile)
    else
      render action: "edit"
    end
  end

  def destroy
    @family.destroy
    flash.notice = "Successfully Deleted Employer Census Family."
    redirect_to employers_employer_profile_path(@employer_profile)
  end

  def delink
    @family.delink_employee_role
    @family.save!
    flash.notice = "Successfully delinked family."
    redirect_to employers_employer_profile_path(@employer_profile)
  end

  def show
  end

  private

  def census_employee_params
    params.require(:employer_census_employee_family).permit(:id, :employer_profile_id,
      :census_employee_attributes => [
          :id, :first_name, :middle_name, :last_name, :name_sfx, :dob, :ssn, :gender, :hired_on,
          :address_attributes => [ :id, :kind, :address_1, :address_2, :city, :state, :zip ],
        ],
      :census_dependents_attributes => [
          :id, :first_name, :last_name, :name_sfx, :dob, :gender, :employee_relationship, :_destroy
        ]
      )
  end

  def find_employer
    @employer_profile = EmployerProfile.find params["employer_profile_id"]
  end

  def find_family
    @family = @employer_profile.employee_families.where(id: params["id"]).to_a.first
  end

  def set_family_id
    params[:id] = params[:family_id]
    find_family
  end

  def build_family
    family = EmployerCensus::EmployeeFamily.new
    family.build_census_employee
    family.build_census_employee.build_address
    family.census_dependents.build
    family
  end

end