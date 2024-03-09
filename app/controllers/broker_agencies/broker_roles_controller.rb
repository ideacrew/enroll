### Handles Broker Registration requests made by anonymous users. Authentication disbaled for this controller.
class BrokerAgencies::BrokerRolesController < ApplicationController
  before_action :assign_filter_and_agency_type

  def create
    # failed_recaptcha_message = "We were unable to verify your reCAPTCHA.  Please try again."
    notice = "Your registration has been submitted. A response will be sent to the email address you provided once your application is reviewed."
    if params[:person].present?
      @broker_candidate = ::Forms::BrokerCandidate.new(applicant_params)
      # if verify_recaptcha(model: @broker_candidate, message: failed_recaptcha_message) && @broker_candidate.save
      if @broker_candidate.save
        flash[:notice] = notice
        render 'confirmation'
      else
        @filter = params[:person][:broker_applicant_type]
        render 'new'
      end
    else
      @organization = ::Forms::BrokerAgencyProfile.new(primary_broker_role_params)
      @organization.languages_spoken = params.require(:organization)[:languages_spoken].reject!(&:empty?) if params.require(:organization)[:languages_spoken].present?
      # if verify_recaptcha(model: @organization, message: failed_recaptcha_message) && @organization.save
      if @organization.save
        flash[:notice] = notice
        render 'confirmation'
      else
        @agency_type = 'new'
        render "new"
      end
    end
  end
  
  def email_guide
    notice = "A copy of the Broker Registration Guide has been emailed to #{params[:email]}"
    flash[:notice] = notice
    UserMailer.broker_registration_guide(params).deliver_now
    render 'confirmation'
  end

  private

  # def convert_to_string(languages_spoken)
  #   # return languages_spoken unless languages_spoken.respond_to?(:join)
  #   languages_spoken.reject!(&:empty?) #.join(',')
  # end

  def assign_filter_and_agency_type
    @filter = params[:filter] || 'broker'
    @agency_type = params[:agency_type] || 'new'
  end

  def primary_broker_role_params
    params.require(:organization).permit(
      :first_name, :last_name, :dob, :email, :npn, :legal_name, :dba,
      :fein, :is_fake_fein, :entity_kind, :home_page, :market_kind, :languages_spoken,
      :working_hours, :accept_new_clients,
      :office_locations_attributes => [
        :address_attributes => [:kind, :address_1, :address_2, :city, :state, :zip, :county],
        :phone_attributes => [:kind, :area_code, :number, :extension]
      ],
      :ach_record => [
        :routing_number, :routing_number_confirmation, :account_number
      ]
    )
  end

  def applicant_params
    params.require(:person).permit(:first_name, :last_name, :dob, :email, :npn, :broker_agency_id, :broker_applicant_type,
     :market_kind, {:languages_spoken => []}, :working_hours, :accept_new_clients,
     :addresses_attributes => [:kind, :address_1, :address_2, :city, :state, :zip, :county])
  end
end
