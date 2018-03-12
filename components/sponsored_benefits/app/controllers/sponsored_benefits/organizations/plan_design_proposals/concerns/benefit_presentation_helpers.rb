module SponsoredBenefits
  module Organizations
    module BenefitPresentationHelpers
      extend ActiveSupport::Concern

      included do
        helper_method :selected_carrier_level, :visit_types
      end

      private

        def selected_carrier_level
          @selected_carrier_level ||= params[:selected_carrier_level]
        end

        def visit_types
          @visit_types ||= ::Products::Qhp::VISIT_TYPES
        end
    end
  end
end
