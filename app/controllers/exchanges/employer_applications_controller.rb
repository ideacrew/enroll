class Exchanges::EmployerApplicationsController < ApplicationController

  before_action :check_hbx_staff_role
  before_action :find_employer

  def index
    @element_to_replace_id = params[:employers_action_id]
  end

  def edit
    @application = @employer_profile.plan_years.find(params[:id])
  end

  def terminate
    @application = @employer_profile.plan_years.find(params[:employer_application_id])
    flash[:notice] = "Employer Application terminated successfully."
    redirect_to exchanges_hbx_profiles_root_path
  end

  def cancel
  end

  def reinstate
  end

  private

  def check_hbx_staff_role
    unless current_user.has_hbx_staff_role?
      redirect_to root_path, :flash => { :error => "You must be an HBX staff member" }
    end
  end

  def find_employer
    @employer_profile = EmployerProfile.find(params[:employer_id])
  end
end