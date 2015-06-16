class BrokerAgencies::ProfilesController < ApplicationController

  before_action :check_broker_role, only: [:new, :create]

  def index
    @broker_agency_profiles = BrokerAgencyProfile.all
  end

  def new
    form = ::Forms::BrokerAgencyProfile.build
    @organization = form
  end

  def create
    params.permit!
    @organization = ::Forms::BrokerAgencyProfile.build(params[:organization])

    if @organization.save(current_user)
      flash[:notice] = "Successfully created Broker Agency Profile"
      redirect_to broker_agencies_profile_path(@organization.broker_agency_profile)
    else
      flash[:error] = "Failed to create Broker Agency Profile"
      render "new"
    end
  end

  def show
    @broker_agency_profile = BrokerAgencyProfile.find(params["id"])
  end

  def employer_view
  end

  private

  def check_broker_role
    if current_user.has_broker_role?
      redirect_to broker_agencies_profile_path(current_user.person.get_broker_profile_contact)
    end
  end

end
