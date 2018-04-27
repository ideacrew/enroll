module BenefitSponsors
  module BenefitApplications
    class BenefitApplicationsController < ApplicationController

      def new
        @benefit_application_form = BenefitSponsors::Forms::BenefitApplicationForm.for_new(params.require(:benefit_sponsorship_id))
      end

      def create
        @benefit_application_form = BenefitSponsors::Forms::BenefitApplicationForm.for_create(application_params)
        if @benefit_application_form.save
          redirect_to new_benefit_sponsorship_benefit_application_benefit_package_path(@benefit_application_form.service.benefit_sponsorship, @benefit_application_form.show_page_model)
        else
          flash[:error] = error_messages(@benefit_application_form)
          render :new
        end
      end

      def edit
        @benefit_application_form = BenefitSponsors::Forms::BenefitApplicationForm.for_edit(params.require(:id))
      end

      def update    
        @benefit_application_form = BenefitSponsors::Forms::BenefitApplicationForm.for_update(params.require(:id))
        if @benefit_application_form.update_attributes(application_params)
          redirect_to benefit_sponsorship_benefit_application_benefit_packages_path(@benefit_application_form.show_page_model.benefit_sponsorship, @benefit_application_form.show_page_model)
        else
          flash[:error] = error_messages(@benefit_application_form)
          render :edit
        end
      end

      private

      def error_messages(instance)
        instance.errors.full_messages.inject(""){|memo, error| "#{memo}<li>#{error}</li>"}.html_safe
      end

      def application_params
        params.require(:benefit_application).permit(
          :start_on, :end_on, :fte_count, :pte_count, :msp_count,
          :open_enrollment_start_on, :open_enrollment_end_on, :benefit_sponsorship_id
        )
      end
    end
  end
end