class BrokerAgencies::ProfilesController < ApplicationController
  before_action :check_broker_agency_staff_role, only: [:new, :create]
  before_action :check_admin_staff_role, only: [:index]
  before_action :find_hbx_profile, only: [:index]
  before_action :find_broker_agency_profile, only: [:show, :edit, :update]

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
     @provider = current_user.person
     @staff_role = current_user.has_broker_agency_staff_role?
  end

  def edit
    @organization = Forms::BrokerAgencyProfile.find(@broker_agency_profile.id)
  end

  def update
    params.permit!
    @organization = Forms::BrokerAgencyProfile.find(@broker_agency_profile.id)

    if @organization.update_attributes(params[:organization])
      flash[:notice] = "Successfully Update Broker Agency Profile"
      redirect_to broker_agencies_profile_path(@broker_agency_profile)
    else
      flash[:error] = "Failed to Update Broker Agency Profile"
      render "edit"
    end
  end
 
  def staff_index
    @q = params.permit(:q)[:q]
    @staff = Person.where(broker_role: {:$exists => true})
    #brokers = brokers.where(:'broker_role.aasm_state'=> 'active')   #FIXME TODO
    @page_alphabets = page_alphabets(@staff, "last_name")
    page_no = cur_page_no(@page_alphabets.first)
    if @q.nil?
      @staff = @staff.where(last_name: /^#{page_no}/i)
    else
      @staff = @staff.where(last_name: @q)
    end 
  end


  def employers
    if current_user.has_broker_agency_staff_role?
      profile = BrokerAgencyProfile.find(params[:id])
      @orgs = Organization.by_broker_agency_profile(profile._id)
    else
      broker_role_id = current_user.person.broker_role._id
      @orgs = Organization.where({'employer_profile.broker_agency_accounts.writing_agent_id' => broker_role_id})
    end
    @page_alphabets = page_alphabets(@orgs, "legal_name")
    page_no = cur_page_no(@page_alphabets.first)
    @organizations = @orgs.where("legal_name" => /^#{page_no}/i)
    @employer_profiles = @organizations.map {|o| o.employer_profile}
  end

  def messages
    @sent_box = true
    @provider = current_user.person
  end

  def agency_messages
    @sent_box = true
    @broker_agency_profile = current_user.person.broker_agency_staff_roles.first.broker_agency_profile
  end

  def inbox
    @sent_box = true
    id = params["id"]||params['profile_id']
    @broker_agency_provider = BrokerAgencyProfile.find(id)
    @folder = (params[:folder] || 'Inbox').capitalize
    if current_user.person._id.to_s == id
      @provider = current_user.person
    else
      @provider = @broker_agency_provider
    end
  end

  private

  def find_hbx_profile
    @profile = current_user.person.hbx_staff_role.hbx_profile
  end

  def find_broker_agency_profile
    @broker_agency_profile = BrokerAgencyProfile.find(params[:id])
  end

  def check_admin_staff_role
    if current_user.has_hbx_staff_role? || current_user.has_csr_role?
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
