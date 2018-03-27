# Takes the given contribution model and produces the needed objects for that
# model to place under the Sponsoring profile.
module BenefitMarkets
  class ContributionModels::ContributionModelBuilder
    # Produce the contribution unit values specified by the given contribution model
    def build_contribution_unit_values(contribution_model)
      contribution_value_kls = contribution_model.contribution_value_kind.constantize
      contribution_model.contribution_units.map do |cu|
        contribution_value_kls.new.tap do |cv|
          cu.assign_contribution_value_defaults(cv)
        end
      end
    end
  end
end
