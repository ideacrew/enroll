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
    @broker_agency = Organization.where({"broker_agency_profile._id" => BSON::ObjectId.from_string(params[:broker_agency_id])}).last.try(:broker_agency_profile)
  end

  def create
    params.permit!
    success = false
    
    if params[:person].present?
      person_params = params[:person]
      applicant_type = person_params.delete(:broker_applicant_type) if person_params[:broker_applicant_type]
      if applicant_type && applicant_type == 'staff_role'
        @person = ::Forms::BrokerAgencyStaffRole.new(person_params)
      else
        @person = ::Forms::BrokerRole.new(person_params)
      end
      if @person.save(current_user)
        success = true
      end
    else
      @organization = ::Forms::BrokerAgencyProfile.new(params[:organization])
      if @organization.save(current_user)
        success = true
      end
    end

    if success
      flash[:notice] = "Your registration has been submitted. A response will be sent to the email address you provided once your application is reviewed."
    else
      flash[:error] = "Failed to create Broker Agency Profile"
    end

    redirect_to "/broker_registration"
  end
end
