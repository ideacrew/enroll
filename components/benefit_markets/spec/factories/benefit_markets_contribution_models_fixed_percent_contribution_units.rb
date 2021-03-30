FactoryBot.define do
  factory :benefit_markets_contribution_models_fixed_percent_contribution_unit, class: 'BenefitMarkets::ContributionModels::FixedPercentContributionUnit' do

    after(:build) do |contribution_unit|
      member_relationship_operator = (contribution_unit.name == "employee") ? :== : :>=

      contribution_unit.member_relationship_maps = [
        build(:benefit_markets_contribution_models_member_relationship_map,
              relationship_name: contribution_unit.name.to_sym,
              operator: member_relationship_operator,
              contribution_unit: contribution_unit,
              count: 1)
      ]
    end

    # trait :with_member_relationship_maps do
    #   member_relationship_maps {
    #   	[
    #   		build(:benefit_markets_contribution_models_member_relationship_map,
    #         relationship_name: name,
    #         operator: member_relationship_operator,
    #         contribution_unit: self,
    #         count: 1)
    #   	]
    #   }
    # end
  end
end
