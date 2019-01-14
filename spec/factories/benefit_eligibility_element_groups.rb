FactoryBot.define do
  factory :benefit_eligibility_element_group do
    association :benefit_package
    market_places           ["individual"]
    enrollment_periods      ["open_enrollment", "special_enrollment"]
    family_relationships    BenefitEligibilityElementGroup::INDIVIDUAL_MARKET_RELATIONSHIP_CATEGORY_KINDS
    benefit_categories      ["health"]
    incarceration_status    ["unincarcerated"]
    age_range               0..0
    citizenship_status      ["us_citizen", "naturalized_citizen", "alien_lawfully_present", "lawful_permanent_resident"]
    residency_status        ["state_resident"]
    ethnicity               ["any"]
    cost_sharing            "any"
    lawful_presence_status  "verification_outstanding"
  end
end
