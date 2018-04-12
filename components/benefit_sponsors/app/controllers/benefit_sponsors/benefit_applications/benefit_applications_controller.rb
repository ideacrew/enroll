module BenefitSponsors
  module BenefitApplications
    class BenefitApplicationsController < ApplicationController

      before_action :load_benefit_sponsorship
      before_action :load_benefit_application, only: [:edit, :update, :delete]

      def new
        @benefit_application_form = BenefitSponsors::Forms::BenefitApplication.new
      end

      def create
        @benefit_application_form = BenefitSponsors::Forms::BenefitApplication.new(@benefit_sponsorship, benefit_application_params)

        if @benefit_application_form.save
          redirect_to new_benefit_sponsorship_benefit_application_benefit_package_path(@benefit_sponsorship, @benefit_application_form.benefit_application)
        else
          flash[:error] = error_messages(@benefit_application_form)
          render :new
        end
      end

      def edit
        @benefit_application_form = BenefitSponsors::Forms::BenefitApplication.load_from_object(@benefit_application)
      end

      def update
        @benefit_application_form = BenefitSponsors::Forms::BenefitApplication.new(@benefit_spnsorship, benefit_application_params)
        @benefit_application_form.reference_benefit_application = @benefit_application
        
        if @benefit_application_form.save
          redirect_to benefit_sponsorship_benefit_application_benefit_packages_path(@benefit_sponsorship, @benefit_application_form.benefit_application)
        else
          flash[:error] = error_messages(@benefit_application_form)
          render :edit
        end
      end

      private

      def load_benefit_sponsorship
        @benefit_sponsorship = BenefitSponsors::BenefitSponsorships::BenefitSponsorship.find(params[:benefit_sponsorship_id])
      end

      def load_benefit_sponsorship
        @benefit_application = @benefit_sponsorship.benefit_applications.find(params[:benefit_application_id])
      end

      def error_messages(instance)
        instance.errors.full_messages.inject(""){|memo, error| "#{memo}<li>#{error}</li>"}.html_safe
      end

      def benefit_application_params
        params.require(:benefit_application).permit(
          :start_on, :end_on, :fte_count, :pte_count, :msp_count,
          :open_enrollment_start_on, :open_enrollment_end_on 
        )
      end
    end
  end
end
