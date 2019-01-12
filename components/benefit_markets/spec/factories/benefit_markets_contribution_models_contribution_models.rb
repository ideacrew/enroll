FactoryBot.define do
  factory :benefit_markets_contribution_models_contribution_model, class: 'BenefitMarkets::ContributionModels::ContributionModel' do
    
    sponsor_contribution_kind { "::BenefitSponsors::SponsoredBenefits::FixedPercentSponsorContribution" }
    contribution_calculator_kind  { "::BenefitSponsors::ContributionCalculators::SimpleShopReferencePlanContributionCalculator" }
    title  { "#{Settings.aca.state_abbreviation} Shop Contribution Model" }
    many_simultaneous_contribution_units { true }

    after(:build) do |contribution_model|

      contribution_model.member_relationships = [
        BenefitMarkets::ContributionModels::MemberRelationship.new(
          relationship_name: "employee",
          relationship_kinds: ["self"]
          ),
        BenefitMarkets::ContributionModels::MemberRelationship.new(
          relationship_name: "spouse",
          relationship_kinds: ["spouse"]
          ),
        BenefitMarkets::ContributionModels::MemberRelationship.new(
          relationship_name: "domestic_partner",
          relationship_kinds: ["life_partner", "domestic_partner"]
          ),
        BenefitMarkets::ContributionModels::MemberRelationship.new(
          relationship_name: "dependent",
          age_threshold: 26,
          age_comparison: :>=,
          disability_qualifier: true,
          relationship_kinds: ["child", "adopted_child", "foster_child", "stepchild", "ward"]
          )
      ]

      contribution_model.contribution_units << build(:benefit_markets_contribution_models_fixed_percent_contribution_unit, 
        name: "employee",
        display_name: "Employee",
        order: 0,
        default_contribution_factor: 0.75,
        member_relationship_maps: [
          BenefitMarkets::ContributionModels::MemberRelationshipMap.new({
            relationship_name: "employee",
            operator: :==,
            count: 1
            })
          ])

      contribution_model.contribution_units << build(:benefit_markets_contribution_models_fixed_percent_contribution_unit, 
        name: "spouse",
        display_name: "Spouse",
        order: 1,
        default_contribution_factor: 0.50,
        member_relationship_maps: [
          BenefitMarkets::ContributionModels::MemberRelationshipMap.new({
            relationship_name: "spouse",
            operator: :>=,
            count: 1
            })
          ])

      contribution_model.contribution_units << build(:benefit_markets_contribution_models_fixed_percent_contribution_unit, 
        name: "domestic_partner",
        display_name: "Domestic Partner",
        order: 2,
        default_contribution_factor: 0.25,
        member_relationship_maps: [
          BenefitMarkets::ContributionModels::MemberRelationshipMap.new({
            relationship_name: "domestic_partner",
            operator: :>=,
            count: 1
            })
          ])

      contribution_model.contribution_units << build(:benefit_markets_contribution_models_fixed_percent_contribution_unit, 
        name: "dependent",
        display_name: "Child Under 26",
        order: 3,
        default_contribution_factor: 0.25,
        member_relationship_maps: [
          BenefitMarkets::ContributionModels::MemberRelationshipMap.new({
            relationship_name: "dependent",
            operator: :>=,
            count: 1
            })
          ])
    end

    trait :for_health_single_product do
      # toDo
    end
  end
end
