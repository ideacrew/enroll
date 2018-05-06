module BenefitSponsors
  module Profiles
    class Employers::EmployerProfilesController < ApplicationController

      before_action :find_employer, only: [:show, :bulk_employee_upload]

      #New person registered with existing organization and approval request submitted to employer
      def show_pending
        authorize [:benefit_sponsors, :employer_profile]
        respond_to do |format|
          format.html
          format.js
        end
      end

      def show
        authorize @employer_profile
        @tab = params['tab']
        if params[:q] || params[:page] || params[:commit] || params[:status]
          # paginate_employees
        else
          case @tab
            when 'benefits'
              @benefit_applications = find_benefit_applications
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
                format.html
                format.js
              end
          end
        end
      end

      def bulk_employee_upload
        file = params.require(:file)
        @form = BenefitSponsors::Forms::RosterUploadForm.call(file, @employer_profile)
        # @census_employee_import = CensusEmployeeImport.new({file:file, employer_profile:@employer_profile})
        begin
        if @form.save
          redirect_to "/employers/employer_profiles/#{@employer_profile.id}?employer_profile_id=#{@employer_profile.id}&tab=employees", :notice=>"#{@census_employee_import.length} records uploaded from CSV"
        else
          render "employers/employer_profiles/employee_csv_upload_errors"
        end
        rescue Exception => e
          # TODO - get redirection path from form obj
          if e.message == "Unrecognized Employee Census spreadsheet format. Contact DC Health Link for current template."
            render "employers/employer_profiles/_download_new_template"
          else
            @census_employee_import.errors.add(:base, e.message)
            render "employers/employer_profiles/employee_csv_upload_errors"
          end
        end
      end

      def inbox
        @folder = params[:folder] || 'Inbox'
        @sent_box = false
      end

      private

      def find_employer
        id_params = params.permit(:id, :employer_profile_id)
        id = id_params[:id] || id_params[:employer_profile_id]
        @organization = BenefitSponsors::Organizations::Organization.employer_profiles.where(:"profiles._id" => BSON::ObjectId.from_string(id)).first
        @employer_profile = @organization.employer_profile
        render file: 'public/404.html', status: 404 if @employer_profile.blank?
      end

      def find_benefit_applications
        @employer_profile.parent.active_benefit_sponsorship.benefit_applications
      end
    end
  end
end
