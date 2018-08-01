module BenefitSponsors
  module SponsoredBenefits
    class SponsoredBenefitsController < ApplicationController

      # before_action :find_benefit_application, :find_employer

      def new
        @sponsored_benefit_form = BenefitSponsors::Forms::BenefitForm.for_new(params)
        # TODO - add pundit policy
      end
    
      private

      # def find_benefit_package
      # end

      # def find_benefit_application
      # end

      # def find_employer
      # end
    end
  end
end
