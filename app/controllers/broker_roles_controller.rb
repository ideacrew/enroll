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
    success = false
    if params[:person].present?
      applicant_type = params[:person][:broker_applicant_type] if params[:person][:broker_applicant_type]
      if applicant_type && applicant_type == 'staff_role'
        @person = ::Forms::BrokerAgencyStaffRole.new(broker_agency_staff_role_params)
      else
        @person = ::Forms::BrokerRole.new(broker_role_params)
      end
      if @person.save(current_user)
        success = true
      end
    else
      @organization = ::Forms::BrokerAgencyProfile.new(primary_broker_role_params)
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


  private

  def primary_broker_role_params
    params.require(:organization).permit(
      :first_name, :last_name, :dob, :email, :npn, :legal_name, :dba, 
      :fein, :entity_kind, :home_page, :market_kind, :languages_spoken, 
      :working_hours, :accept_new_clients,
      :office_locations_attributes => [ 
        :address_attributes => [:kind, :address_1, :address_2, :city, :state, :zip], 
        :phone_attributes => [:kind, :area_code, :number, :extension]
      ]
    )
  end

  def broker_role_params
    params.require(:person).permit(:first_name, :last_name, :dob, :email, :npn, :broker_agency_id)
  end

  def broker_agency_staff_role_params
    params.require(:person).permit(:first_name, :last_name, :dob, :email, :broker_agency_id)
  end
end
