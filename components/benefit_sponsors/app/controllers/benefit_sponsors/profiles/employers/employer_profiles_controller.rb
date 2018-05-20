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
              @benefit_applications = @employer_profile.benefit_applications
            when 'documents'
            when 'employees'
              @datatable = Effective::Datatables::EmployeeDatatable.new({id: params[:id], scopes: params[:scopes]})
              # @current_plan_year = @employer_profile.show_plan_year
              # paginate_employees
            when 'brokers'
              @broker_agency_account = @employer_profile.active_broker_agency_account
            when 'inbox'

            else
              @broker_agency_account = @employer_profile.active_broker_agency_account
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

      def export_census_employees
        respond_to do |format|
          format.csv { send_data @employer_profile.census_employees.sorted.to_csv, filename: "#{@employer_profile.legal_name.parameterize.underscore}_census_employees_#{TimeKeeper.date_of_record}.csv" }
        end
      end

      def bulk_employee_upload
        authorize @employer_profile, :show?
        file = params.require(:file)
        @roster_upload_form = BenefitSponsors::Forms::RosterUploadForm.call(file, @employer_profile)
        begin
          if @roster_upload_form.save
            redirect_to @roster_upload_form.redirection_url
          else
            render @roster_upload_form.redirection_url
          end
        rescue Exception => e
          @roster_upload_form.errors.add(:base, e.message)
          render (@roster_upload_form.redirection_url || default_url)
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

      def default_url
        "employers/employer_profiles/employee_csv_upload_errors"
      end
    end
  end
end
