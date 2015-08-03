class BrokerAgencies::ProfilesController < ApplicationController
  before_action :check_broker_agency_staff_role, only: [:new, :create]
  before_action :check_admin_staff_role, only: [:index]
  before_action :find_hbx_profile, only: [:index]

  def index
    @broker_agency_profiles = BrokerAgencyProfile.all
  end

  def new
    @organization = ::Forms::BrokerAgencyProfile.new
  end

  def create
    params.permit!
    @organization = ::Forms::BrokerAgencyProfile.new(params[:organization])

    if @organization.save(current_user)
      flash[:notice] = "Successfully created Broker Agency Profile"
      redirect_to broker_agencies_profile_path(@organization.broker_agency_profile)
    else
      flash[:error] = "Failed to create Broker Agency Profile"
      render "new"
    end
  end

  def show
    @broker_agency_profile = BrokerAgencyProfile.find(params[:id])
  end

  def employers
    profile = BrokerAgencyProfile.find(params[:id])
    @orgs = Organization.where({'employer_profile.broker_agency_accounts.broker_agency_profile_id' => profile._id})
    @page_alphabets = page_alphabets(@orgs, "legal_name")
    page_no = cur_page_no(@page_alphabets.first)
    @organizations = @orgs.where("legal_name" => /^#{page_no}/i)
    @employer_profiles = @organizations.map {|o| o.employer_profile}
  end

  def messages
    @sent_box = true
    @broker_agency_profile = BrokerAgencyProfile.find(params[:id])
  end

  def inbox
    @sent_box = true
    @broker_agency_provider = BrokerAgencyProfile.find(params["id"]||params['profile_id'])
    @folder = (params[:folder] || 'Inbox').capitalize
  end

  private

  def find_hbx_profile
    @profile = current_user.person.hbx_staff_role.hbx_profile
  end

  def check_admin_staff_role
    if current_user.has_hbx_staff_role?
    elsif current_user.has_broker_agency_staff_role?
      redirect_to broker_agencies_profile_path(:id => current_user.person.broker_agency_staff_roles.first.broker_agency_profile_id)
    else
      redirect_to new_broker_agencies_profile_path
    end
  end

  def check_broker_agency_staff_role
    if current_user.has_broker_agency_staff_role?
      redirect_to broker_agencies_profile_path(:id => current_user.person.broker_agency_staff_roles.first.broker_agency_profile_id)
    elsif current_user.has_broker_role?
      redirect_to broker_agencies_profile_path(:id => current_user.person.broker_role.broker_agency_profile_id)
    else
      flash[:notice] = "You don't have a Broker Agency Profile associated with your Account!! Please register your Broker Agency first."
    end
  end
end
