# Takes the given contribution model and produces the needed objects for that
# model to place under the Sponsoring profile.
module BenefitMarkets
  class ContributionModels::ContributionModelBuilder
    # Produce the contribution levels specified by the given contribution model
    def build_contribution_levels(contribution_model)
      contribution_level_kind = contribution_model.contribution_level_kind.constantize
      contribution_model.contribution_units.map do |cu|
        contribution_level_kind.new.tap do |cv|
          cu.assign_contribution_value_defaults(cv)
        end
      end
    end
  end
end
