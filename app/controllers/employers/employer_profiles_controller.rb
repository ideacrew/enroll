class Employers::EmployerProfilesController < ApplicationController
  before_filter :find_employer, only: [:show, :destroy]

  def index
    @employer_profiles = EmployerProfile.all.to_a
  end

  def my_account
  end

  def show
    @current_plan_year = @employer_profile.plan_years.last
    @benefit_groups = @current_plan_year.benefit_groups
  end

  def new
    @organization = build_employer_profile
  end

  def create
    params.permit!
    employer_profile = EmployerProfile.new
    @organization = employer_profile.build_organization
    @organization.attributes = params["organization"]
    if @organization.save
      flash.notice = 'Employer successfully created.'
      redirect_to employers_employer_profiles_path
    else
      render action: "new"
    end
  end

  def destroy
    @employer_profile.destroy

    respond_to do |format|
      format.html { redirect_to employers_employer_index_path, notice: "Employer successfully deleted." }
      format.json { head :no_content }
    end
  end

  private

  def find_employer
    @employer_profile = EmployerProfile.find(params[:id])
  end

  def employer_params
    params.require(:employer).permit(:legal_name, :fein, :entity_kind)
  end

  def build_employer_profile
    employer_profile = EmployerProfile.new
    organization = employer_profile.build_organization
    organization.office_locations.build
    organization.office_locations.first.build_address
    organization.office_locations.first.build_email
    organization.office_locations.first.build_phone
    organization
  end
end
