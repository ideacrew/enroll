# frozen_string_literal: true

require_dependency "benefit_sponsors/application_controller"

module BenefitSponsors
  module Profiles
    # This controller is responsible for creating/updating new broker agencies
    class RegistrationsController < ::BenefitSponsors::ApplicationController
      include BenefitSponsors::Concerns::ProfileRegistration

      rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
      # TODO: Let's just doo this for now
      before_action :redirect_if_general_agency_disabled, only: %i[new create edit update destroy]
      before_action :set_cache_headers, only: [:edit, :new]

      layout 'two_column', :only => :edit

      def new
        @agency = BenefitSponsors::Organizations::OrganizationForms::RegistrationForm.for_new(profile_type: profile_type, portal: params[:portal])
        authorize @agency
        authorize @agency, :redirect_home?
        set_ie_flash_by_announcement unless is_employer_profile?
        respond_to do |format|
          format.html
          format.js
          format.json { head :ok }
        end
      end

      def create #rubocop:disable Metrics/CyclomaticComplexity
        @agency = BenefitSponsors::Organizations::OrganizationForms::RegistrationForm.for_create(registration_params)
        authorize @agency
        begin
          saved, result_url = verify_recaptcha_if_needed && @agency.save
          if saved && is_employer_profile?
              create_sso_account(current_user, current_person, 15, "employer") do
              end
          elsif saved && is_general_agency_profile?
            flash[:notice] = "Your registration has been submitted. A response will be sent to the email address you provided once your application is reviewed."
          end
          template_filename = if redirect_to_requirements_after_confirmation?
                                "confirmation"
                              else
                                "broker_agencies/broker_roles/extended_confirmation"
                              end
          if is_broker_profile? && saved
            flash[:notice] = "Your registration has been submitted. A response will be sent to the email address you provided once your application is reviewed."
            respond_to do |format|
              format.html { render template_filename, :layout => 'single_column' }
            end
            return
          elsif saved
            result_url = self.send(result_url)
            redirect_to result_url
            return
          end
        rescue StandardError => e
          flash[:error] = e.message
        end
        params[:profile_type] = profile_type
        respond_to do |format|
          format.html { render 'new', :flash => { :error => @agency.errors.full_messages } }
        end
      end

      def edit
        @agency = BenefitSponsors::Organizations::OrganizationForms::RegistrationForm.for_edit(profile_id: params[:id])
        authorize @agency

        render layout: 'single_column' if @agency.organization.is_broker_profile? || @agency.organization.is_general_agency_profile?
      end

      def update
        @agency = BenefitSponsors::Organizations::OrganizationForms::RegistrationForm.for_update(registration_params)
        authorize @agency
        updated, result_url = @agency.update
        result_url = self.send(result_url)
        if updated
          flash[:notice] = 'Employer successfully Updated.' if is_employer_profile?
          flash[:notice] = 'Broker Agency Profile successfully Updated.' if is_broker_profile?
          flash[:notice] = 'General Agency Profile successfully Updated.' if is_general_agency_profile?
        else
          org_error_msg = @agency.errors.full_messages.join(",").humanize if @agency.errors.present?

          flash[:error] = "Employer information not saved. #{org_error_msg}."
        end
        redirect_to result_url
      end

      def counties_for_zip_code
        @counties = BenefitMarkets::Locations::CountyZip.where(zip: params[:zip_code]).pluck(:county_name).uniq

        respond_to do |format|
          format.json { render json: @counties }
        end
      end

      def resource_not_found
        render file: 'public/404.html', status: 404
      end

      private

      def redirect_if_general_agency_disabled
        redirect_to(main_app.root_path, notice: l10n("general_agency_not_enabled")) if !EnrollRegistry.feature_enabled?(:general_agency) && is_general_profile?
      end

      def profile_type
        valid_profile_types = %w[benefit_sponsor broker_agency general_agency].freeze
        profile_type_constant_name = params[:profile_type] || params.dig(:agency, :profile_type) || @agency&.profile_type
        @profile_type = (profile_type_constant_name if valid_profile_types.include?(profile_type_constant_name))
      end

      def default_template
        :new
      end

      def is_employer_profile?
        profile_type == "benefit_sponsor"
      end

      def is_broker_profile?
        profile_type == "broker_agency"
      end

      def is_general_profile?
        profile_type == "general_agency"
      end

      def is_general_agency_profile?
        profile_type == "general_agency"
      end

      def registration_params
        current_user_id = current_user.present? ? current_user.id : nil
        agency_params = params.permit(agency: {})
        agency_params[:agency].merge!({:profile_id => params["id"], :current_user_id => current_user_id})
      end

      def organization_params
        org_params = params.require(:agency).require(:organization).permit(
          :legal_name, :dba, :fein, :entity_kind, :sic_code,
          :profile_attributes => {
            :office_locations_attributes => [
              {:address_attributes => [:kind, :address_1, :address_2, :city, :state, :zip, :county]},
              {:phone_attributes => [:kind, :area_code, :number, :extension]},
              {:email_attributes => [:kind, :address]},
              :is_primary
            ]
          }
        )

        org_params[:profile_attributes][:office_locations_attributes].delete_if {|_key, value| value.blank?} if org_params[:profile_attributes][:office_locations_attributes].present?

        org_params
      end

      def current_person
        current_user.reload # devise current user not loading changes
        current_user.person
      end

      def redirect_to_requirements_after_confirmation?
        EnrollRegistry.feature_enabled?(:redirect_to_requirements_page_after_confirmation)
      end

      def user_not_authorized(exception)
        action = exception.query.to_sym

        case action
        when :redirect_home?
          if current_user
            redirect_to self.send(:agency_home_url, exception.record.profile_id)
          else
            session[:custom_url] = main_app.new_user_session_path
            super
          end
        when :new?
          params_hash = params.permit(:profile_type, :controller, :action)
          session[:portal] = url_for(params_hash)
          redirect_to self.send(:sign_up_url)
        else
          session[:custom_url] = main_app.new_user_registration_path unless current_user
          super
        end
      end

      def verify_recaptcha_if_needed
        return true unless helpers.registration_recaptcha_enabled?(profile_type)
        verify_recaptcha(model: @agency)
      end
    end
  end
end
