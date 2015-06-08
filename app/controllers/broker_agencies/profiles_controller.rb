class BrokerAgencies::ProfilesController < ApplicationController

  before_action :check_broker_role, only: [:new, :create]

  def index
    @broker_agency_profiles = BrokerAgencyProfile.all
  end

  def new
    form = ::Forms::BrokerAgencyProfileForm.new({},{})
    @organization = form.build_broker_agency_profile_params
  end

  def create
    params.permit!
    form = ::Forms::BrokerAgencyProfileForm.new(params, current_user)
    @organization, user = form.build_and_assign_attributes

    if @organization.save && user.save
      flash[:notice] = "Successfully created Broker Agency Profile"
      redirect_to broker_agencies_profile_path(current_user.person.broker_agency_contact)
    else
      flash[:error] = "Failed to create Broker Agency Profile"
      render "new"
    end
  end

  def show
    @broker_agency_profile = BrokerAgencyProfile.find(params["id"])
  end

  private

  def check_broker_role
    if current_user.has_broker_role?
      redirect_to broker_agencies_profile_path(current_user.person.get_broker_profile_contact)
    end
  end

end