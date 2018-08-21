module BenefitSponsors
  module SponsoredBenefits
    class SponsoredBenefitsController < ApplicationController

      # before_action :find_benefit_application, :find_employer

      def new
        @sponsored_benefit_form = BenefitSponsors::Forms::SponsoredBenefitForm.for_new_benefit(params.permit(:kind, :benefit_sponsorship_id, :benefit_application_id, :benefit_package_id))
        # TODO - add pundit policy
      end

      def create
        @sponsored_benefit_form = BenefitSponsors::Forms::SponsoredBenefitForm.for_create(identifier_params.merge(sponsored_benefits_params))
        # TODO - add pundit policy

        if @sponsored_benefit_form.save
          flash[:notice] = "Benefit Package successfully created."
          redirect_to profiles_employers_employer_profile_path(@sponsored_benefit_form.service.profile, :tab=>'benefits')
        else
          flash[:error] = error_messages(@sponsored_benefit_form)
          render :new
        end
      end

      def edit
        @sponsored_benefit_form = BenefitSponsors::Forms::SponsoredBenefitForm.for_edit(params.permit(:kind, :benefit_sponsorship_id, :benefit_application_id, :benefit_package_id, :id))
        # TODO - add pundit policy
      end

      def update
        @sponsored_benefit_form = BenefitSponsors::Forms::SponsoredBenefitForm.for_update(identifier_params.merge(sponsored_benefits_params))
        # TODO - add pundit policy
        if @sponsored_benefit_form.update
          flash[:notice] = "Benefit Package successfully updated."
          redirect_to profiles_employers_employer_profile_path(@sponsored_benefit_form.service.profile, :tab=>'benefits')
        else
          flash[:error] = error_messages(@sponsored_benefit_form)
          render :edit
        end
      end

      def destroy
        binding.pry
      @sponsored_benefit_form = BenefitSponsors::Forms::SponsoredBenefitForm.for_destroy(params.permit(:kind, :benefit_sponsorship_id, :benefit_application_id, :benefit_package_id, :id))

        if @sponsored_benefit_form.destroy
          flash[:notice] = "Dental Benefit Package successfully deleted."
          redirect_to profiles_employers_employer_profile_path(@sponsored_benefit_form.service.profile, :tab=>'benefits')
        #  render :js => "window.location = #{profiles_employers_employer_profile_path(@sponsored_benefit_form.service.profile, :tab=>'benefits').to_json}"
        else
          flash[:error] = error_messages(@sponsored_benefit_form)
        #  render :js => "window.location = #{profiles_employers_employer_profile_path(@sponsored_benefit_form.service.profile, :tab=>'benefits').to_json}"
        end
      end

      def change_reference_product
        @sponsored_benefit_form = BenefitSponsors::Forms::SponsoredBenefitForm.fetch(params.permit(:kind, :benefit_sponsorship_id, :benefit_application_id, :benefit_package_id, :id))
      end

      private

      def error_messages(object)
        object.errors.full_messages.inject(""){|memo, error| "#{memo}<li>#{error}</li>"}.html_safe
      end

      def identifier_params
        params.permit(:id, :benefit_sponsorship_id, :benefit_application_id, :benefit_package_id)
      end

      def sponsored_benefits_params
        params.require(:sponsored_benefits).permit(:id, :kind, :product_option_choice,
          :product_package_kind, :reference_plan_id,
          :sponsor_contribution_attributes => [
            :contribution_levels_attributes => [:id, :is_offered, :display_name, :contribution_factor,:contribution_unit_id]
          ]
        )
      end
    end
  end
end
