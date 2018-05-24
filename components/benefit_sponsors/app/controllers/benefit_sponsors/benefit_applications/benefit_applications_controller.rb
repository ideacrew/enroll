module BenefitSponsors
  module BenefitApplications
    class BenefitApplicationsController < ApplicationController
      layout "two_column"
      include Pundit

      def new
        @benefit_application_form = BenefitSponsors::Forms::BenefitApplicationForm.for_new(params.require(:benefit_sponsorship_id))
        authorize @benefit_application_form, :updateable?
      end

      def create
        @benefit_application_form = BenefitSponsors::Forms::BenefitApplicationForm.for_create(application_params)
        authorize @benefit_application_form, :updateable?
        if @benefit_application_form.save
          redirect_to new_benefit_sponsorship_benefit_application_benefit_package_path(@benefit_application_form.service.benefit_sponsorship, @benefit_application_form.show_page_model)
        else
          flash[:error] = error_messages(@benefit_application_form)
          render :new
        end
      end

      def edit
        @benefit_application_form = BenefitSponsors::Forms::BenefitApplicationForm.for_edit(params.permit(:id, :benefit_sponsorship_id))
        authorize @benefit_application_form, :updateable?
      end

      def update    
        @benefit_application_form = BenefitSponsors::Forms::BenefitApplicationForm.for_update(params.require(:id))
        authorize @benefit_application_form, :updateable?
        if @benefit_application_form.update_attributes(application_params)
          redirect_to edit_benefit_sponsorship_benefit_application_benefit_package_path(@benefit_application_form.show_page_model.benefit_sponsorship, @benefit_application_form.show_page_model, @benefit_application_form.show_page_model.benefit_packages.first)
        else
          flash[:error] = error_messages(@benefit_application_form)
          render :edit
        end
      end

      def submit_application
        @benefit_application_form = BenefitSponsors::Forms::BenefitApplicationForm.fetch(params.require(:benefit_application_id))
        authorize @benefit_application_form, :updateable?
        if @benefit_application_form.submit_application
          flash[:notice] = "Benefit Application successfully published."
          flash[:error] = error_messages(@benefit_application_form)
          redirect_to profiles_employers_employer_profile_path(@benefit_application_form.show_page_model.benefit_sponsorship.profile, tab: 'benefits')
        else
          flash[:error] = "Benefit Application failed to submit. #{error_messages(@benefit_application_form)}"
          redirect_to profiles_employers_employer_profile_path(@benefit_application_form.show_page_model.benefit_sponsorship.profile, tab: 'benefits')
        end
      end

      def force_submit_application
        @benefit_application_form = BenefitSponsors::Forms::BenefitApplicationForm.fetch(params.require(:benefit_application_id))
        authorize @benefit_application_form, :updateable?
        if @benefit_application_form.force_submit_application
          flash[:error] = "As submitted, this application is ineligible for coverage under the #{Settings.site.short_name} exchange. If information that you provided leading to this determination is inaccurate, you have 30 days from this notice to request a review by DCHL officials."
          redirect_to profiles_employers_employer_profile_path(@benefit_application_form.show_page_model.benefit_sponsorship.profile, tab: 'benefits')
        end
      end

      def revert
        @benefit_application_form = BenefitSponsors::Forms::BenefitApplicationForm.fetch(params.require(:benefit_application_id))
        authorize @benefit_application_form, :revert_application?
        flash[:error] = error_messages(@benefit_application_form) unless @benefit_application_form.revert
        redirect_to profiles_employers_employer_profile_path(@benefit_application_form.show_page_model.benefit_sponsorship.profile, tab: 'benefits')
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