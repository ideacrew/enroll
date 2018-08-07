module BenefitSponsors
  module SponsoredBenefits
    class SponsoredBenefitsController < ApplicationController

      # before_action :find_benefit_application, :find_employer

      def new
        @sponsored_benefit_form = BenefitSponsors::Forms::BenefitForm.for_new(params.permit(:kind, :benefit_sponsorship_id, :benefit_package_id))
        # TODO - add pundit policy
      end

      def create
        @sponsored_benefit_form = BenefitSponsors::Forms::BenefitForm.for_create(sponsored_benefits_params)
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
        @sponsored_benefit_form = BenefitSponsors::Forms::BenefitForm.for_edit(params.permit(:kind, :benefit_sponsorship_id, :benefit_package_id, :id))
      end

      private

      # def find_benefit_package
      # end

      # def find_benefit_application
      # end

      # def find_employer
      # end

      def error_messages(object)
        object.errors.full_messages.inject(""){|memo, error| "#{memo}<li>#{error}</li>"}.html_safe
      end

      def sponsored_benefits_params
        params.require(:benefits).permit(:kind, :benefit_sponsorship_id, :benefit_package_id,
          :sponsored_benefit_attributes => [:id, :kind, :product_option_choice, :product_package_kind, :reference_plan_id,
            :sponsor_contribution_attributes => [ 
              :contribution_levels_attributes => [:id, :is_offered, :display_name, :contribution_factor,:contribution_unit_id]
            ]
          ]
        )
      end
    end
  end
end
