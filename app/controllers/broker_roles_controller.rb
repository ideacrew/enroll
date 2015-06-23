### Handles Broker Registration requests made by anonymous users. Authentication disbaled for this controller.
class BrokerRolesController < ApplicationController

  def new
    @person = Forms::BrokerCandidate.new
    @organization = ::Forms::BrokerAgencyProfile.new
    @orgs = Organization.exists(broker_agency_profile: true)
    @broker_agency_profiles = @orgs.map(&:broker_agency_profile)

    @filter = params[:filter] || 'broker_role'
    @agency_type = params[:agency_type] || 'existing'

    respond_to do |format|
      format.html
      format.js
    end
  end

  def search_broker_agency
    orgs = Organization.exists(broker_agency_profile: true).where(legal_name: /#{params[:broker_agency_search]}/i)
    broker_agency_profiles_by_name = orgs.present? ? orgs.map(&:broker_agency_profile) : []

    pers = Person.where({"broker_role.npn" => params[:broker_agency_search]})
    broker_agency_profiles_by_npn = pers.present? ? pers.map(&:broker_role).map(&:broker_agency_profile) : []
    @broker_agency_profiles = (broker_agency_profiles_by_name | broker_agency_profiles_by_npn).compact
  end

  def create
    params.permit!
    if params[:person].present?
      person_params = params[:person]
      applicant_type = person_params.delete(:broker_applicant_type) if person_params[:broker_applicant_type]
      if applicant_type && applicant_type == 'staff_role'
        @person = ::Forms::BrokerAgencyStaffRole.new(person_params)
      else
        @person = ::Forms::BrokerRole.new(person_params)
      end
      if @person.save(current_user)
        flash[:notice] = "Your registration has been submitted. A response will be sent to the email address you provided once your application is reviewed."
        redirect_to "/broker_registration"
      else
        flash[:error] = "Failed to create Broker Agency Profile"
        @person = Forms::BrokerCandidate.new
        redirect_to "/broker_registration"
      end
    else
      @organization = ::Forms::BrokerAgencyProfile.new(params[:organization])
      if @organization.save(current_user)
        flash[:notice] = "Your registration has been submitted. A response will be sent to the email address you provided once your application is reviewed."
        redirect_to "/broker_registration"
      else
        flash[:error] = "Failed to create Broker Agency Profile"
        @person = Forms::BrokerCandidate.new
        redirect_to "/broker_registration"
      end
    end
  end

  def thank_you
  end
end
