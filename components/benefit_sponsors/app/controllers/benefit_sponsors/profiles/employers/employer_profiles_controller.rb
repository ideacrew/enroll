module BenefitSponsors
  module Profiles
    class Employers::EmployerProfilesController < ApplicationController
      include BenefitSponsors::Employers::EmployerHelper
      before_action :get_site_key
      before_action :initiate_employer_profile, only: [:create]
      before_action :find_employer, only: [:show, :edit, :update, :show_profile, :destroy, :inbox,
                                           :bulk_employee_upload, :bulk_employee_upload_form, :download_invoice, :export_census_employees, :link_from_quote, :generate_checkbook_urls]
      before_action :check_employer_staff_role, only: [:new]

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

      #New person registered with existing organization and approval request submitted to employer
      def show_pending
        respond_to do |format|
          format.html {render "benefit_sponsors/profiles/employers/employer_profiles/show_pending.html.erb"}
          format.js
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
              respond_to do |format|
                format.html {render "benefit_sponsors/profiles/employers/employer_profiles/show.html.erb"}
                format.js
              end
          end
        end
      end

      def edit
        @staff ||= staff_for_benefit_sponsors_employer_including_pending(@employer_profile)
      end

      def update
        sanitize_office_locations_params
        if can_update_profile?
          if @organization.update_attributes(params["organization"])
            flash[:notice] = 'Employer successfully Updated.'
            redirect_to edit_profiles_employers_employer_profile_path(@employer_profile)
          else
            org_error_msg = @organization.errors.full_messages.join(",").humanize if @organization.errors.present?

            flash[:error] = "Employer information not saved. #{org_error_msg}."
            redirect_to edit_profiles_employers_employer_profile_path(@employer_profile)
          end
        else
          flash[:error] = 'You do not have permissions to update the details'
          redirect_to edit_profiles_employers_employer_profile_path(@employer_profile)
        end
      end

      def sanitize_office_locations_params
        # TODO - implement in accepts_nested_attributes_for
        params["organization"].permit!
        params[:organization][:profiles_attributes].each do |key, profile|
          profile[:office_locations_attributes].each do |key, location|
            if location && location[:address_attributes]
              location[:is_primary] = (location[:address_attributes][:kind] == 'primary')
            end
          end
        end
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

      #checks if person is approved by employer for staff role
      #Redirects to home page of employer profile if approved
      #person with pending/denied approval will be redirected to new registration page
      def check_employer_staff_role
        if current_user.person && current_user.person.has_active_benefit_sponsors_employer_staff_role?
          redirect_to profiles_employers_employer_profile_path(:id => current_user.person.active_benefit_sponsors_employer_staff_roles.first.employer_profile_id, :tab => "home")
        end
      end

      def can_update_profile?
        (current_user.has_employer_staff_role? && @employer_profile.staff_roles.include?(current_user.person)) || current_user.person.agent?
      end
    end
  end
end
