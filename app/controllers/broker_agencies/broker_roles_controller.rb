### Handles Broker Registration requests made by anonymous users. Authentication disbaled for this controller.
class BrokerAgencies::BrokerRolesController < ApplicationController
  before_action :assign_filter_and_agency_type

  def new_broker
    @broker_candidate = Forms::BrokerCandidate.new

    respond_to do |format|
      format.html { render 'new' }
      format.js
    end
  end

  def new_staff_member
    @broker_candidate = Forms::BrokerCandidate.new

    respond_to do |format|
      format.js
    end
  end

  def new_broker_agency
    @organization = Forms::BrokerAgencyProfile.new

    respond_to do |format|
      format.js
    end
  end

  def search_broker_agency
    orgs = Organization.exists(broker_agency_profile: true).or({legal_name: /#{params[:broker_agency_search]}/i}, {"broker_agency_profile.corporate_npn" => /#{params[:broker_agency_search]}/i})

    @broker_agency_profiles = orgs.present? ? orgs.map(&:broker_agency_profile) : []
  end

  def create
    if params[:person].present?
      @broker_candidate = ::Forms::BrokerCandidate.new(applicant_params)
      if @broker_candidate.save
        flash[:notice] = "Your registration has been submitted. A response will be sent to the email address you provided once your application is reviewed."
        redirect_to broker_registration_path
      else
        @filter = params[:person][:broker_applicant_type]
        render 'new'
      end
    else
      @organization = ::Forms::BrokerAgencyProfile.new(primary_broker_role_params)
      @organization.languages_spoken = params.require(:organization)[:languages_spoken].reject!(&:empty?) if params.require(:organization)[:languages_spoken].present?
      if @organization.save
        flash[:notice] = "Your registration has been submitted. A response will be sent to the email address you provided once your application is reviewed."
        redirect_to broker_registration_path
      else
        @agency_type = 'new'
        render "new"
      end
    end
  end

  private

  # def convert_to_string(languages_spoken)
  #   # return languages_spoken unless languages_spoken.respond_to?(:join)
  #   languages_spoken.reject!(&:empty?) #.join(',')
  # end

  def assign_filter_and_agency_type
    @filter = params[:filter] || 'broker'
    @agency_type = params[:agency_type] || 'existing'
  end

  def primary_broker_role_params
    params.require(:organization).permit(
      :first_name, :last_name, :dob, :email, :npn, :legal_name, :dba, 
      :fein, :entity_kind, :corporate_npn, :home_page, :market_kind, :languages_spoken,
      :working_hours, :accept_new_clients,
      :office_locations_attributes => [ 
        :address_attributes => [:kind, :address_1, :address_2, :city, :state, :zip], 
        :phone_attributes => [:kind, :area_code, :number, :extension]
      ]
    )
  end

  def applicant_params
    params.require(:person).permit(:first_name, :last_name, :dob, :email, :npn, :broker_agency_id, :broker_applicant_type)
  end
end
