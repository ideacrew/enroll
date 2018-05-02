module BenefitSponsors
  module Profiles
    class Employers::EmployerProfilesController < ApplicationController

      before_action :find_employer, only: [:show]

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
                format.html
                format.js
              end
          end
        end
      end

      private

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
