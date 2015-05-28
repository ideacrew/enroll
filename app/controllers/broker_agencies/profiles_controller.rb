class BrokerAgencies::ProfilesController < ApplicationController

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
    current_user.person.broker_agency_contact = broker_agency_profile
    current_user.roles << "broker" unless current_user.roles.include?("broker")

    if @organization.save && current_user.save
      flash[:notice] = "Successfully created Broker Agency Profile."
      redirect_to broker_agencies_profile_path(current_user.person.broker_agency_contact)
    else
      binding.pry
      render "new"
    end
  end

  def show
  end

  private

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