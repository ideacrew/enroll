module BenefitSponsors
  module BenefitApplications
    class BenefitApplicationsController < ApplicationController

      def new
        @benefit_application = BenefitSponsors::Forms::BenefitApplication.new(application_params)
      end

      def create
        @benefit_application = BenefitSponsors::Forms::BenefitApplication.new(application_params)

        if @benefit_application.save
          redirect_to new_benefit_sponsorship_benefit_application_benefit_package_path(@benefit_application.benefit_sponsorship, @benefit_application.resource)
        else
          flash[:error] = error_messages(@benefit_application)
          render :new
        end
      end

      def edit
        @benefit_application = BenefitSponsors::Forms::BenefitApplication.new(application_params)
      end

      def update
        @benefit_application = BenefitSponsors::Forms::BenefitApplication.new(application_params)
        
        if @benefit_application.save
          redirect_to benefit_sponsorship_benefit_application_benefit_packages_path(@benefit_application.benefit_sponsorship, @benefit_application.resource)
        else
          flash[:error] = error_messages(@benefit_application)
          render :edit
        end
      end

      def recommend_dates
        @benefit_application = BenefitSponsors::Forms::BenefitApplication.new(application_params)

        if params[:start_on].present?
          start_on = params[:start_on].to_date
          @result = @benefit_application.check_start_on(start_on)

          if @result[:result] == "ok"
            @open_enrollment_dates = @benefit_application.calculate_open_enrollment_date(start_on)
            @schedule = @benefit_application.shop_enrollment_timetable(start_on)
          end
        end
      end

      private

      def error_messages(instance)
        instance.errors.full_messages.inject(""){|memo, error| "#{memo}<li>#{error}</li>"}.html_safe
      end

      def application_params
        params.permit(
          :benefit_sponsorship_id,
          :benefit_application => [
            :id, :start_on, :end_on, :fte_count, :pte_count, :msp_count,
            :open_enrollment_start_on, :open_enrollment_end_on 
          ]
        )
      end
    end
  end
end