module BenefitSponsors
  module Profiles
    class Employers::EmployerProfilesController < ApplicationController
      before_action :get_site_key
      before_action :initiate_employer_profile, only: [:create]
      before_action :find_employer, only: [:show, :edit, :show_profile, :destroy, :inbox,
                                       :bulk_employee_upload, :bulk_employee_upload_form, :download_invoice, :export_census_employees, :link_from_quote, :generate_checkbook_urls]

      def new
        @sponsor = Organizations::Factories::BenefitSponsorFactory.new(nil)
      end

      def create
        begin
          organization_saved, pending = @sponsor.save(current_user)
        rescue Exception => e
          flash[:error] = e.message
          render action: "new"
          return
        end
        if organization_saved
          @person = current_user.person
          create_sso_account(current_user, current_user.person, 15, "employer") do
            if pending
              # flash[:notice] = 'Your Employer Staff application is pending'
              render action: 'show_pending'
            else
              # employer_account_creation_notice if @sponsor.employer_profile.present?
              redirect_to profiles_employers_employer_profile_path(@sponsor.profile.id, tab: 'home')
            end
          end
        else
          render action: "new"
        end
      end

      def show
        @tab = params['tab']
        if params[:q] || params[:page] || params[:commit] || params[:status]
          # paginate_employees
        else
          case @tab
          when 'benefits'
            # @current_plan_year = @employer_profile.renewing_plan_year || @employer_profile.active_plan_year
            # sort_plan_years(@employer_profile.plan_years)
          when 'documents'
          when 'employees'
            # @current_plan_year = @employer_profile.show_plan_year
            # paginate_employees
          when 'brokers'
            # @broker_agency_accounts = @employer_profile.broker_agency_accounts
          when 'inbox'

          else
            # @broker_agency_accounts = @employer_profile.broker_agency_accounts
            # @current_plan_year = @employer_profile.show_plan_year
            # collect_and_sort_invoices(params[:sort_order])
            # @sort_order = params[:sort_order].nil? || params[:sort_order] == "ASC" ? "DESC" : "ASC"

            # set_flash_by_announcement if @tab == 'home'
          end
        end
      end

      def edit
        @staff = Person.staff_for_employer_including_pending(@employer_profile)
        # This & respective views should go to ER staff roles controller TODO
        # @add_staff = params[:add_staff]
      end

      def update
        sanitize_office_locations_params

        @organization = BenefitSponsors::Organizations::Organization.employer_profiles.where(:"profiles._id" => BSON::ObjectId.from_string(params[:id])).first
        @employer_profile = @organization.employer_profile
        @org_office_locations_dup = @organization.office_locations.as_json

        #TODO check if this is used
        # @employer = @employer_profile.match_employer(current_user)

        if (current_user.has_employer_staff_role? && @employer_profile.staff_roles.include?(current_user.person)) || current_user.person.agent?
          @organization.assign_attributes(organization_profile_params)

          #clear office_locations, don't worry, we will recreate
          @organization.assign_attributes(:office_locations => [])
          @organization.save(validate: false)

          if @organization.update_attributes(employer_profile_params)
            #TODO for new model
            # @organization.notify_legal_name_or_fein_change
            # @organization.notify_address_change(@organization_dup,employer_profile_params)
            flash[:notice] = 'Employer successfully Updated.'
            redirect_to edit_profiles_employers_employer_profile_path(@employer_profile)
          else
            org_error_msg = @organization.errors.full_messages.join(",").humanize if @organization.errors.present?

            #in case there was an error, reload from saved json
            @organization.assign_attributes(:office_locations => @organization_dup)
            @organization.save(validate: false)
            #@organization.reload
            flash[:error] = "Employer information not saved. #{org_error_msg}."
            redirect_to edit_profiles_employers_employer_profile_path(@employer_profile)
          end
        else
          flash[:error] = 'You do not have permissions to update the details'
          redirect_to edit_profiles_employers_employer_profile_path(@employer_profile)
        end
      end

      def sanitize_office_locations_params
        params[:organization][:office_locations_attributes].each do |key, location|
          params[:organization][:office_locations_attributes].delete(key) unless location['address_attributes']
          location.delete('phone_attributes') if (location['phone_attributes'].present? && location['phone_attributes']['number'].blank?)
          office_locations = params[:organization][:office_locations_attributes]
          if office_locations && office_locations[key]
            params[:organization][:office_locations_attributes][key][:is_primary] = (office_locations[key][:address_attributes][:kind] == 'primary')
          end
        end
      end

      def organization_profile_params
        params.require(:organization).permit(
            :id,
            :legal_name,
            :dba,
            :entity_kind
        )
      end

      def employer_profile_params
        params.require(:organization).permit(
            :legal_name,
            :dba,
            :entity_kind,
            :office_locations_attributes => [
                {:address_attributes => [:kind, :address_1, :address_2, :city, :state, :zip]},
                {:phone_attributes => [:kind, :area_code, :number, :extension]},
                {:email_attributes => [:kind, :address]},
                :is_primary
            ]
        )
      end

      private

      def get_site_key
        @site_key = self.class.superclass.current_site.site_key
      end

      def initiate_employer_profile
        params[:sponsor].permit!
        if @site_key == :dc
          @profile = Organizations::AcaShopDcEmployerProfile.new
        elsif @site_key == :cca
          @profile = Organizations::AcaShopCcaEmployerProfile.new
        end
        @sponsor = Organizations::Factories::BenefitSponsorFactory.new(@profile, params[:sponsor])
      end

      def find_employer
        id_params = params.permit(:id, :employer_profile_id)
        id = id_params[:id] || id_params[:employer_profile_id]
        @organization = BenefitSponsors::Organizations::Organization.employer_profiles.where(:"profiles._id" => BSON::ObjectId.from_string(params[:id])).first
        @employer_profile = @organization.employer_profile
        render file: 'public/404.html', status: 404 if @employer_profile.blank?
      end
    end
  end
end
