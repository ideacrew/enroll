class Hbx::HbxController < ApplicationController
  before_action :check_hbx_staff_role, except: [:welcome]

  def welcome
  end

  def show
    @hbx_role = current_user.person.hbx_role
  end

  def employer_index
    @employer_profiles = EmployerProfile.all
  end

  def broker_agency_index
    @broker_agency_profiles = BrokerAgencyProfile.all
  end

  def insured_index
  end

private
  def check_hbx_staff_role
    unless current_user.has_hbx_staff_role?
      redirect_to root_path, :flash => { :error => "You must be an HBX staff member" }
    end
  end
end
