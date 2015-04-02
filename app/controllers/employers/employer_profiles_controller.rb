class Employers::EmployerProfilesController < ApplicationController

  def index
    @employer_profiles = EmployerProfile.all.to_a
  end

  # My Account page
  def show
    @employer_profile = EmployerProfile.find(params[:id])
    @current_plan_year = @employer_profile.plan_years.last
    @benefit_groups = @current_plan_year.benefit_groups
  end

  def new
    @employer_profile = EmployerProfile.new
  end

end
