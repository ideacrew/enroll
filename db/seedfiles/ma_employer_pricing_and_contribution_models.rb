# Composite Pricing Models
composite_employer_pricing_units = [
  BenefitMarkets::PricingModels::TieredPricingUnit.new(
    name: "employee_only",
    display_name: "Employee Only",
    order: 0,
    member_relationship_maps: [
      BenefitMarkets::PricingModels::MemberRelationshipMap.new({
        relationship_name: "employee",
        operator: :==,
        count: 1
      }),
      BenefitMarkets::PricingModels::MemberRelationshipMap.new({
        relationship_name: "spouse",
        operator: :==,
        count: 0
      }),
      BenefitMarkets::PricingModels::MemberRelationshipMap.new({
        relationship_name: "dependent",
        operator: :==,
        count: 0
      })
    ]
  ),
  BenefitMarkets::PricingModels::TieredPricingUnit.new(
    name: "employee_and_spouse",
    display_name: "Employee and Spouse",
    order: 1,
    member_relationship_maps: [
      BenefitMarkets::PricingModels::MemberRelationshipMap.new({
        relationship_name: "employee",
        operator: :==,
        count: 1
      }),
      BenefitMarkets::PricingModels::MemberRelationshipMap.new({
        relationship_name: "spouse",
        operator: :==,
        count: 1 
      }),
      BenefitMarkets::PricingModels::MemberRelationshipMap.new({
        relationship_name: "dependent",
        operator: :==,
        count: 0
      })
    ]
  ),
  BenefitMarkets::PricingModels::TieredPricingUnit.new(
    name: "employee_and_one_or_more_dependents",
    display_name: "Employee and Dependents",
    order: 2,
    member_relationship_maps: [
      BenefitMarkets::PricingModels::MemberRelationshipMap.new({
        relationship_name: "employee",
        operator: :==,
        count: 1
      }),
      BenefitMarkets::PricingModels::MemberRelationshipMap.new({
        relationship_name: "spouse",
        operator: :==,
        count: 0
      }),
      BenefitMarkets::PricingModels::MemberRelationshipMap.new({
        relationship_name: "dependent",
        operator: :>=,
        count: 1
      })
    ]
  ),
  BenefitMarkets::PricingModels::TieredPricingUnit.new(
    name: "family",
    display_name: "Family",
    order: 3,
    member_relationship_maps: [
      BenefitMarkets::PricingModels::MemberRelationshipMap.new({
        relationship_name: "employee",
        operator: :==,
        count: 1
      }),
      BenefitMarkets::PricingModels::MemberRelationshipMap.new({
        relationship_name: "spouse",
        operator: :==,
        count: 1
      }),
      BenefitMarkets::PricingModels::MemberRelationshipMap.new({
        relationship_name: "dependent",
        operator: :>=,
        count: 1
      })
    ]
  )
]

composite_employer_member_relationships = [
  BenefitMarkets::PricingModels::MemberRelationship.new(
    relationship_name: "employee",
    relationship_kinds: ["self"]
  ),
  BenefitMarkets::PricingModels::MemberRelationship.new(
    relationship_name: "spouse",
    relationship_kinds: ["spouse", "life_partner"]
  ),
  BenefitMarkets::PricingModels::MemberRelationship.new(
    relationship_name: "dependent",
    age_threshold: 26,
    age_comparison: :<,
    relationship_kinds: ["child", "adopted_child","foster_child","stepchild", "ward"]
  ),
  BenefitMarkets::PricingModels::MemberRelationship.new(
    relationship_name: "dependent",
    age_threshold: 26,
    age_comparison: :>=,
    disability_qualifier: true,
    relationship_kinds: ["child", "adopted_child","foster_child","stepchild", "ward"]
  )
]

pricing_model = BenefitMarkets::PricingModels::PricingModel.create!(
  :product_multiplicities => [:single],
  :price_calculator_kind => "::BenefitSponsors::PricingCalculators::CcaCompositeTieredPriceCalculator",
  :pricing_units => composite_employer_pricing_units,
  :member_relationships => composite_employer_member_relationships,
  :name => "MA Composite Price Model"
)

composite_employer_contribution_relationships = [
  BenefitMarkets::ContributionModels::MemberRelationship.new(
    relationship_name: "employee",
    relationship_kinds: ["self"]
  ),
  BenefitMarkets::ContributionModels::MemberRelationship.new(
    relationship_name: "dependent",
    relationship_kinds: ["spouse", "life_partner"]),
  BenefitMarkets::ContributionModels::MemberRelationship.new(
    relationship_name: "dependent",
    age_threshold: 26,
    age_comparison: :<,
    relationship_kinds: ["child", "adopted_child","foster_child","stepchild", "ward"]),
  BenefitMarkets::ContributionModels::MemberRelationship.new(
    relationship_name: "dependent",
    age_threshold: 26,
    age_comparison: :>=,
    disability_qualifier: true,
    relationship_kinds: ["child", "adopted_child","foster_child","stepchild", "ward"])
]

composite_employer_contribution_units = [
  BenefitMarkets::ContributionModels::FixedPercentContributionUnit.new(
    name: "employee",
    display_name: "Employee Only",
    order: 0,
    default_contribution_factor: 0.75,
    minimum_contribution_factor: 0.50,
    member_relationship_maps: [
      BenefitMarkets::ContributionModels::MemberRelationshipMap.new({
        relationship_name: "employee",
        operator: :==,
        count: 1
      }),
      BenefitMarkets::ContributionModels::MemberRelationshipMap.new({
        relationship_name: "dependent",
        operator: :==,
        count: 0 
      })
    ]
  ),
  BenefitMarkets::ContributionModels::FixedPercentContributionUnit.new(
    name: "family",
    display_name: "Family",
    order: 1,
    default_contribution_factor: 0.50,
    member_relationship_maps: [
      BenefitMarkets::ContributionModels::MemberRelationshipMap.new({
        relationship_name: "employee",
        operator: :==,
        count: 1
      }),
      BenefitMarkets::ContributionModels::MemberRelationshipMap.new({
        relationship_name: "dependent",
        operator: :>=,
        count: 1
      })
    ]
  )
]

# Composite Contribution Models
composite_contribution_model = BenefitMarkets::ContributionModels::ContributionModel.create!({
  product_multiplicities: [:single],
  sponsor_contribution_kind: "::BenefitSponsors::SponsoredBenefits::FixedPercentSponsorContribution",
  contribution_calculator_kind: "::BenefitSponsors::ContributionCalculators::TieredPercentContributionCalculator",
  contribution_units: composite_employer_contribution_units,
  member_relationships: composite_employer_contribution_relationships,
  name: "MA Composite Contribution Model"
})

# List Bill Pricing Models
employer_pricing_units = [
  BenefitMarkets::PricingModels::RelationshipPricingUnit.new(
    name: "employee",
    display_name: "Employee",
    order: 0
  ),
  BenefitMarkets::PricingModels::RelationshipPricingUnit.new(
    name: "spouse",
    display_name: "Spouse",
    order: 1
  ),
  BenefitMarkets::PricingModels::RelationshipPricingUnit.new(
    name: "dependent",
    display_name: "Dependents",
    order: 2,
    discounted_above_threshold: 4,
    eligible_for_threshold_discount: true
  )
]

employer_member_relationships = [
  BenefitMarkets::PricingModels::MemberRelationship.new(
    relationship_name: "employee",
    relationship_kinds: ["self"]
  ),
  BenefitMarkets::PricingModels::MemberRelationship.new(
    relationship_name: "spouse",
    relationship_kinds: ["spouse", "life_partner"]
  ),
  BenefitMarkets::PricingModels::MemberRelationship.new(
    relationship_name: "dependent",
    age_threshold: 26,
    age_comparison: :<,
    relationship_kinds: ["child", "adopted_child","foster_child","stepchild", "ward"]
  ),
  BenefitMarkets::PricingModels::MemberRelationship.new(
    relationship_name: "dependent",
    age_threshold: 26,
    age_comparison: :>=,
    disability_qualifier: true,
    relationship_kinds: ["child", "adopted_child","foster_child","stepchild", "ward"]
  )
]

pricing_model = BenefitMarkets::PricingModels::PricingModel.create!(
  :price_calculator_kind => "::BenefitSponsors::PricingCalculators::CcaShopListBillPricingCalculator",
  :pricing_units => employer_pricing_units,
  :member_relationships => employer_member_relationships,
  :name => "MA List Bill Shop Pricing Model"
)

# List Bill Contribution Models

employer_contribution_relationships = [
  BenefitMarkets::ContributionModels::MemberRelationship.new(
    relationship_name: "employee",
    relationship_kinds: ["self"]
  ),
  BenefitMarkets::ContributionModels::MemberRelationship.new(
    relationship_name: "spouse",
    relationship_kinds: ["spouse", "life_partner"]
  ),
  BenefitMarkets::ContributionModels::MemberRelationship.new(
    relationship_name: "dependent",
    relationship_kinds: ["child", "adopted_child","foster_child","stepchild", "ward"]
  )
]

employer_contribution_units = [
  BenefitMarkets::ContributionModels::FixedPercentContributionUnit.new(
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
    ]
  ),
  BenefitMarkets::ContributionModels::FixedPercentContributionUnit.new(
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
    ]
  ),
  BenefitMarkets::ContributionModels::FixedPercentContributionUnit.new(
    name: "dependent",
    display_name: "Dependent",
    order: 2,
    default_contribution_factor: 0.25,
    member_relationship_maps: [
      BenefitMarkets::ContributionModels::MemberRelationshipMap.new({
        relationship_name: "dependent",
        operator: :>=,
        count: 1
      })
    ]
  )
]

contribution_model = BenefitMarkets::ContributionModels::ContributionModel.create!({
  sponsor_contribution_kind: "::BenefitSponsors::SponsoredBenefits::FixedPercentSponsorContribution",
  contribution_calculator_kind: "::BenefitSponsors::ContributionCalculators::CcaShopReferencePlanContributionCalculator",
  contribution_units: employer_contribution_units,
  member_relationships: employer_contribution_relationships,
  name: "MA List Bill Shop Contribution Model"
})
