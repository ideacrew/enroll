module SponsoredBenefits
  module Organizations
    module BenefitGroupAccessors
      extend ActiveSupport::Concern

      included do
        helper_method :benefit_group
      end

      private
        def benefit_group
          @benefit_group ||= sponsorship.benefit_applications.first.benefit_groups.first || sponsorship.benefit_applications.first.benefit_groups.build(benefit_group_params)
        end

        def benefit_group_params
          params.require(:benefit_group).permit(
                      :reference_plan_id,
                      :plan_option_kind,
                      relationship_benefits_attributes: [:relationship, :premium_pct, :offered],
                      composite_tier_contributions_attributes: [:composite_rating_tier, :employer_contribution_percent, :offered]
          )
        end
    end
  end
end
