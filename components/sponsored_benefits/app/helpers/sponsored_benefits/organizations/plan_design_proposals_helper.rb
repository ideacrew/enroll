# frozen_string_literal: true

module SponsoredBenefits
  module Organizations
    # PlanDesignProposalsHelper
    module PlanDesignProposalsHelper
      def display_standard_plan(plan)
        if plan.is_standard_plan
          l10n("yes")
        elsif plan.is_standard_plan == false
          l10n("no")
        else
          "N/A"
        end
      end
    end
  end
end
