namespace :import do
  desc "Create 2018 IVL Benefit package"
  task :benefit_package_2018, [:file] => :environment do |task, args|
    puts "::: Creating IVL 2018 benefit packages :::"

    # BenefitPackages - HBX 2018
    hbx = HbxProfile.current_hbx

    # Second lowest cost silver plan
    slcsp_2018 = Plan.where(active_year: 2018).and(hios_id: "94506DC0390014-01").first

    # check if benefit package is present for 2018
    bc_period_2018 = hbx.benefit_sponsorship.benefit_coverage_periods.select { |bcp| bcp.start_on.year == 2018 }.first

    if !bc_period_2018.present?
    # create benefit package and benefit_coverage_period for 2018
      bc_period_2017 = hbx.benefit_sponsorship.benefit_coverage_periods.select { |bcp| bcp.start_on.year == 2017 }.first
      bc_period_2018 = bc_period_2017.dup
      bc_period_2018.title = "Individual Market Benefits 2018"
      bc_period_2018.start_on = bc_period_2017.start_on + 1.year
      bc_period_2018.end_on = bc_period_2017.end_on + 1.year

      # if we need to change these dates after running this rake task in test or prod environments,
      # we should write a separate script.
      bc_period_2018.open_enrollment_start_on = Settings.aca.individual_market.open_enrollment.start_on
      bc_period_2018.open_enrollment_end_on = Settings.aca.individual_market.open_enrollment.end_on

      bc_period_2018.slcsp = slcsp_2018.id
      bc_period_2018.slcsp_id = slcsp_2018.id

      bs = hbx.benefit_sponsorship
      bs.benefit_coverage_periods << bc_period_2018
      bs.save
    end

    # bc_period_2018 = hbx.benefit_sponsorship.benefit_coverage_periods.select { |bcp| bcp.start_on.year == 2018 }.first
    # bc_period_2018.second_lowest_cost_silver_plan = slcsp_2018

    ivl_health_plans_2018         = Plan.individual_health_by_active_year(2018).health_metal_nin_catastropic.entries.collect(&:_id)
    ivl_dental_plans_2018         = Plan.individual_dental_by_active_year(2018).entries.collect(&:_id)
    ivl_and_cat_health_plans_2018 = Plan.individual_health_by_active_year(2018).entries.collect(&:_id)

    # shop_health_plans_2018        = Plan.shop_health_by_active_year(2018).entries.collect(&:_id)
    # shop_dental_plans_2018        = Plan.shop_dental_by_active_year(2018).entries.collect(&:_id)


    ## 2018 Benefit Packages

    individual_health_benefit_package = BenefitPackage.new(
      title: "individual_health_benefits_2018",
      elected_premium_credit_strategy: "unassisted",
      benefit_ids:          ivl_health_plans_2018,
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

    individual_dental_benefit_package = BenefitPackage.new(
      title: "individual_dental_benefits_2018",
      elected_premium_credit_strategy: "unassisted",
      benefit_ids:          ivl_dental_plans_2018,
      benefit_eligibility_element_group: BenefitEligibilityElementGroup.new(
          market_places:        ["individual"],
          enrollment_periods:   ["open_enrollment", "special_enrollment"],
          family_relationships: BenefitEligibilityElementGroup::INDIVIDUAL_MARKET_RELATIONSHIP_CATEGORY_KINDS,
          benefit_categories:   ["dental"],
          incarceration_status: ["unincarcerated"],
          age_range:            0..0,
          citizenship_status:   ["us_citizen", "naturalized_citizen", "alien_lawfully_present", "lawful_permanent_resident"],
          residency_status:     ["state_resident"],
          ethnicity:            ["any"]
        )
    )

    individual_catastrophic_health_benefit_package = BenefitPackage.new(
      title: "catastrophic_health_benefits_2018",
      elected_premium_credit_strategy: "unassisted",
      benefit_ids:          ivl_and_cat_health_plans_2018,
      benefit_eligibility_element_group: BenefitEligibilityElementGroup.new(
        market_places:        ["individual"],
        enrollment_periods:   ["open_enrollment", "special_enrollment"],
        family_relationships: BenefitEligibilityElementGroup::INDIVIDUAL_MARKET_RELATIONSHIP_CATEGORY_KINDS,
        benefit_categories:   ["health"],
        incarceration_status: ["unincarcerated"],
        age_range:            0..30,
        citizenship_status:   ["us_citizen", "naturalized_citizen", "alien_lawfully_present", "lawful_permanent_resident"],
        residency_status:     ["state_resident"],
        ethnicity:            ["any"]
      )
    )

    native_american_health_benefit_package = BenefitPackage.new(
      title: "native_american_health_benefits_2018",
      elected_premium_credit_strategy: "unassisted",
      benefit_ids:          ivl_health_plans_2018,
      benefit_eligibility_element_group: BenefitEligibilityElementGroup.new(
        market_places:        ["individual"],
        enrollment_periods:   ["open_enrollment", "special_enrollment"],
        family_relationships: BenefitEligibilityElementGroup::INDIVIDUAL_MARKET_RELATIONSHIP_CATEGORY_KINDS,
        benefit_categories:   ["health"],
        incarceration_status: ["unincarcerated"],
        age_range:            0..0,
        citizenship_status:   ["us_citizen", "naturalized_citizen", "alien_lawfully_present", "lawful_permanent_resident"],
        residency_status:     ["state_resident"],
        ethnicity:            ["indian_tribe_member"]
      )
    )

    native_american_dental_benefit_package = BenefitPackage.new(
      title: "native_american_dental_benefits_2018",
      elected_premium_credit_strategy: "unassisted",
      benefit_ids:          ivl_dental_plans_2018,
      benefit_eligibility_element_group: BenefitEligibilityElementGroup.new(
        market_places:        ["individual"],
        enrollment_periods:   ["any"],
        family_relationships: BenefitEligibilityElementGroup::INDIVIDUAL_MARKET_RELATIONSHIP_CATEGORY_KINDS,
        benefit_categories:   ["dental"],
        incarceration_status: ["unincarcerated"],
        age_range:            0..0,
        citizenship_status:   ["us_citizen", "naturalized_citizen", "alien_lawfully_present", "lawful_permanent_resident"],
        residency_status:     ["state_resident"],
        ethnicity:            ["indian_tribe_member"]
      )
    )

    ivl_health_plans_2018_for_csr_100 = Plan.individual_health_by_active_year_and_csr_kind(2018, "csr_100").entries.collect(&:_id)
    ivl_health_plans_2018_for_csr_94 = Plan.individual_health_by_active_year_and_csr_kind(2018, "csr_94").entries.collect(&:_id)
    ivl_health_plans_2018_for_csr_87 = Plan.individual_health_by_active_year_and_csr_kind(2018, "csr_87").entries.collect(&:_id)
    ivl_health_plans_2018_for_csr_73 = Plan.individual_health_by_active_year_and_csr_kind(2018, "csr_73").entries.collect(&:_id)

    individual_health_benefit_package_for_csr_100 = BenefitPackage.new(
      title: "individual_health_benefits_csr_100_2018",
      elected_premium_credit_strategy: "allocated_lump_sum_credit",
      benefit_ids:          ivl_health_plans_2018_for_csr_100,
      benefit_eligibility_element_group: BenefitEligibilityElementGroup.new(
        market_places:        ["individual"],
        enrollment_periods:   ["open_enrollment", "special_enrollment"],
        family_relationships: BenefitEligibilityElementGroup::INDIVIDUAL_MARKET_RELATIONSHIP_CATEGORY_KINDS,
        benefit_categories:   ["health"],
        incarceration_status: ["unincarcerated"],
        age_range:            0..0,
        cost_sharing:         "csr_100",
        citizenship_status:   ["us_citizen", "naturalized_citizen", "alien_lawfully_present", "lawful_permanent_resident"],
        residency_status:     ["state_resident"],
        ethnicity:            ["any"]
      )
    )

    individual_health_benefit_package_for_csr_94 = BenefitPackage.new(
      title: "individual_health_benefits_csr_94_2018",
      elected_premium_credit_strategy: "allocated_lump_sum_credit",
      benefit_ids:          ivl_health_plans_2018_for_csr_94,
      benefit_eligibility_element_group: BenefitEligibilityElementGroup.new(
        market_places:        ["individual"],
        enrollment_periods:   ["open_enrollment", "special_enrollment"],
        family_relationships: BenefitEligibilityElementGroup::INDIVIDUAL_MARKET_RELATIONSHIP_CATEGORY_KINDS,
        benefit_categories:   ["health"],
        incarceration_status: ["unincarcerated"],
        age_range:            0..0,
        cost_sharing:         "csr_94",
        citizenship_status:   ["us_citizen", "naturalized_citizen", "alien_lawfully_present", "lawful_permanent_resident"],
        residency_status:     ["state_resident"],
        ethnicity:            ["any"]
      )
    )

    individual_health_benefit_package_for_csr_87 = BenefitPackage.new(
      title: "individual_health_benefits_csr_87_2018",
      elected_premium_credit_strategy: "allocated_lump_sum_credit",
      benefit_ids:          ivl_health_plans_2018_for_csr_87,
      benefit_eligibility_element_group: BenefitEligibilityElementGroup.new(
        market_places:        ["individual"],
        enrollment_periods:   ["open_enrollment", "special_enrollment"],
        family_relationships: BenefitEligibilityElementGroup::INDIVIDUAL_MARKET_RELATIONSHIP_CATEGORY_KINDS,
        benefit_categories:   ["health"],
        incarceration_status: ["unincarcerated"],
        age_range:            0..0,
        cost_sharing:         "csr_87",
        citizenship_status:   ["us_citizen", "naturalized_citizen", "alien_lawfully_present", "lawful_permanent_resident"],
        residency_status:     ["state_resident"],
        ethnicity:            ["any"]
      )
    )

    individual_health_benefit_package_for_csr_73 = BenefitPackage.new(
      title: "individual_health_benefits_csr_73_2018",
      elected_premium_credit_strategy: "allocated_lump_sum_credit",
      benefit_ids:          ivl_health_plans_2018_for_csr_73,
      benefit_eligibility_element_group: BenefitEligibilityElementGroup.new(
        market_places:        ["individual"],
        enrollment_periods:   ["open_enrollment", "special_enrollment"],
        family_relationships: BenefitEligibilityElementGroup::INDIVIDUAL_MARKET_RELATIONSHIP_CATEGORY_KINDS,
        benefit_categories:   ["health"],
        incarceration_status: ["unincarcerated"],
        age_range:            0..0,
        cost_sharing:         "csr_73",
        citizenship_status:   ["us_citizen", "naturalized_citizen", "alien_lawfully_present", "lawful_permanent_resident"],
        residency_status:     ["state_resident"],
        ethnicity:            ["any"]
      )
    )

    bc_period_2018.benefit_packages = [
        individual_health_benefit_package,
        individual_dental_benefit_package,
        individual_catastrophic_health_benefit_package,
        native_american_health_benefit_package,
        native_american_dental_benefit_package,
        individual_health_benefit_package_for_csr_100,
        individual_health_benefit_package_for_csr_94,
        individual_health_benefit_package_for_csr_87,
        individual_health_benefit_package_for_csr_73
      ]

    bc_period_2018.save!
  end
end