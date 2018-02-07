class Api::V1::BrokerAgencies::BrokerRolesController < ApiController
  before_action :assign_filter_and_agency_type
  skip_before_action :verify_jwt_token
  
  def create
    notice = "Your registration has been submitted. A response will be sent to the email address you provided once your application is reviewed."
    if params[:person].present?
      @broker_candidate = ::Forms::BrokerCandidate.new(applicant_params)
      if @broker_candidate.save
        render json: {message: notice}
      else
        @filter = params[:person][:broker_applicant_type]
        render json: {status: 401}
      end
    else
      @organization = ::Forms::BrokerAgencyProfile.new(primary_broker_role_params)
      @organization.languages_spoken = params.require(:organization)[:languages_spoken]
      if @organization.save
        render json: {message: @organization}
      else
        @agency_type = 'new'
        render json: {status: @organization.errors}
      end
    end
  end
  
  private

  def assign_filter_and_agency_type
    @filter = params[:filter] || 'broker'
    @agency_type = params[:agency_type] || 'new'
  end

  def primary_broker_role_params
    params.require(:organization).permit(
    :first_name, :last_name, :dob, :email, :npn, :legal_name, :dba,
    :fein, :is_fake_fein, :entity_kind, :home_page, :market_kind,
    :working_hours, :accept_new_clients,
    :languages_spoken => [],
    :office_locations_attributes => [
      :address_attributes => [:kind, :address_1, :address_2, :city, :state, :zip],
      :phone_attributes => [:kind, :area_code, :number, :extension]
    ]
    )
  end

  def applicant_params
    params.require(:person).permit(:first_name, :last_name, :dob, :email, :npn, :broker_agency_id, :broker_applicant_type,
    :market_kind, {:languages_spoken => []}, :working_hours, :accept_new_clients, 
    :addresses_attributes => [:kind, :address_1, :address_2, :city, :state, :zip])
  end
  
end