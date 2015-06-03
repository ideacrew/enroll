class BrokerAgencies::ProfilesController < ApplicationController
  before_action :check_broker_role, only: [:new, :create]

  def index
    @broker_agency_profiles = BrokerAgencyProfile.all
  end

  def new
    build_broker_agency_profile_params
  end

  def create
    params.permit!
    build_organization
    @organization.attributes = params[:organization]
    broker_agency_profile = @organization.broker_agency_profile
    broker_role = broker_agency_profile.broker_agency_contacts.first.broker_role
    broker_agency_profile.primary_broker_role = broker_role
    @person = current_user.person.present? ? current_user.person : current_user.build_person(first_name: params[:first_name], last_name: params[:last_name])
    @person.broker_agency_contact = broker_agency_profile
    broker_role.broker_agency_profile = broker_agency_profile
    current_user.roles << "broker" unless current_user.roles.include?("broker")

    if @organization.save && current_user.save
      flash[:notice] = "Successfully created Broker Agency Profile."
      redirect_to broker_agencies_profile_path(current_user.person.broker_agency_contact)
    else
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

  def build_broker_agency_profile_params
    build_organization
    build_office_location
    build_broker_agency
  end

  def build_organization
    @organization = Organization.new
    @broker_agency_profile = @organization.build_broker_agency_profile
  end

  def build_office_location
    @organization.office_locations.build unless @organization.office_locations.present?
    office_location = @organization.office_locations.first
    office_location.build_address unless office_location.address.present?
    office_location.build_phone unless office_location.phone.present?
  end

  def build_broker_agency
    @broker_agency_profile.broker_agency_contacts.build unless @broker_agency_profile.broker_agency_contacts.present?
    broker_agency_contact = @broker_agency_profile.broker_agency_contacts.first
    broker_agency_contact.emails.build unless broker_agency_contact.emails.present?
    broker_agency_contact.build_broker_role unless broker_agency_contact.broker_role.present?
  end
end