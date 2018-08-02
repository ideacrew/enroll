module BenefitSponsors
  module SponsoredBenefits
    class SponsoredBenefitsController < ApplicationController

      # before_action :find_benefit_application, :find_employer

      def new
        @sponsored_benefit_form = BenefitSponsors::Forms::BenefitForm.for_new(sponsored_benefits_params)
        # TODO - add pundit policy
      end

      def create
      end
    
      private

      # def find_benefit_package
      # end

      # def find_benefit_application
      # end

      # def find_employer
      # end

      def sponsored_benefits_params
        params.permit(:id, :sponsored_benefit_kind, :benefit_sponsorship_id, :benefit_package_id)
      end
    end
  end
end
