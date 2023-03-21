# frozen_string_literal: true

module SponsoredBenefits
  module Organizations
    # PlanDesignProposalsHelper
    module PlanDesignProposalsHelper
      def display_standard_plan(plan)
        if plan.is_standard_plan
          l10n('yes')
        elsif plan.is_standard_plan == false
          l10n('no')
        else
          'N/A'
        end
      end

      def broker_quote_hc4cc_subsidy_enabled?
        EnrollRegistry.feature_enabled?(:broker_quote_hc4cc_subsidy)
      end

      def aca_shop_osse_subsidy_enabled?
        EnrollRegistry.feature_enabled?(:aca_shop_osse_subsidy)
      end

      def broker_can_create_hc4cc_quote?
        aca_shop_osse_subsidy_enabled? && broker_quote_hc4cc_subsidy_enabled?
      end
    end
  end
end
