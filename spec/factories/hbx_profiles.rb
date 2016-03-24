FactoryGirl.define do
  factory :hbx_profile do
    organization            { FactoryGirl.build(:organization) }
    us_state_abbreviation   "DC"
    cms_id   "DC0"
    benefit_sponsorship { FactoryGirl.build(:benefit_sponsorship) }

    trait :open_enrollment_coverage_period do
       benefit_sponsorship { FactoryGirl.build(:benefit_sponsorship, :open_enrollment_coverage_period) }
    end

    trait :no_open_enrollment_coverage_period do
      benefit_sponsorship { FactoryGirl.build(:benefit_sponsorship, :no_open_enrollment_coverage_period) }
    end

    trait :ivl_2015_benefit_package do
      after :create do |hbx|

        ivl_2015_benefit_coverage_period = FactoryGirl.create(
                                                              :benefit_coverage_period,
                                                              benefit_sponsorship: hbx.benefit_sponsorship,
                                                              start_on: Date.new(2015,1,1),
                                                              end_on: Date.new(2015,12,31),
                                                              open_enrollment_start_on: Date.new(2015,1,1),
                                                              open_enrollment_end_on: Date.new(2015,12,31)
        )

        ivl_plan = FactoryGirl.create :plan, :with_premium_tables, market: 'individual', coverage_kind: 'health', deductible: 1000, metal_level: "silver", csr_variant_id: "01"

        ivl_2015_benefit_package = FactoryGirl.create(:benefit_package,
                                                      benefit_coverage_period: ivl_2015_benefit_coverage_period,
                                                      title: "individual_health_benefits_2015",
                                                      elected_premium_credit_strategy: "unassisted",
                                                      benefit_ids:          [ivl_plan.id],
                                                      benefit_eligibility_element_group: BenefitEligibilityElementGroup.new(
                                                          market_places:        ["individual"],
                                                          enrollment_periods:   ["open_enrollment", "special_enrollment"],
                                                          family_relationships: BenefitEligibilityElementGroup::INDIVIDUAL_MARKET_RELATIONSHIP_CATEGORY_KINDS,
                                                          benefit_categories:   ["health"],
                                                          incarceration_status: ["unincarcerated"],
                                                          age_range:            0..0,
                                                          citizenship_status:   ["us_citizen", "naturalized_citizen", "alien_lawfully_present", "lawful_permanent_resident"],
                                                          residency_status:     ["state_resident"],
                                                          ethnicity:            ["any"]
                                                      )
        )
        hbx.save!
      end
    end
  end
end
