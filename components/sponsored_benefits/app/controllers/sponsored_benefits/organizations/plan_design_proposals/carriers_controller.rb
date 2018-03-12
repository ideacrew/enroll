module SponsoredBenefits
  module Organizations
    class PlanDesignProposals::CarriersController < ApplicationController
      include SponsoredBenefits::Organizations::PlanDesigners
      include SponsoredBenefits::Organizations::BenefitPresentationHelpers

      def index
        @carrier_names = ::Organization.load_carriers(
                            primary_office_location: plan_design_organization.primary_office_location,
                            selected_carrier_level: selected_carrier_level,
                            active_year: active_year
                            )
      end

      private
        helper_method :active_year

        def active_year
          params[:active_year]
        end
    end
  end
end
