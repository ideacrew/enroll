namespace :update_benefit_packages do
  desc "update benefit_packages ivl 2015 and 2016 for applicant-status and medicaid-eligible"
  task :applicant_and_medicaid => :environment do
    puts "*"*80
    puts "updating benefit_packages ivl 2015 and 2016 for applicant-status and medicaid-eligible"

    hbx = HbxProfile.current_hbx
    bc_period_for_2016 = hbx.benefit_sponsorship.benefit_coverage_periods.select { |bcp| bcp.start_on.year == 2016 }.first
    bc_period_for_2015 = hbx.benefit_sponsorship.benefit_coverage_periods.select { |bcp| bcp.start_on.year == 2015 }.first

    bc_period_for_2015.benefit_packages.update_all({"benefit_eligibility_element_group"=>{"applicant_status"=> ["applicant"]}})
    bc_period_for_2015.benefit_packages.update_all({"benefit_eligibility_element_group"=>{"medicaid_eligibility"=> ["non_eligible"]}})
    puts bc_period_for_2015.benefit_packages.map(&:benefit_eligibility_element_group).map(&:applicant_status).to_s
    puts bc_period_for_2015.benefit_packages.map(&:benefit_eligibility_element_group).map(&:medicaid_eligibility).to_s
    puts "2015 benefit_package update complete"


    bc_period_for_2016.benefit_packages.update_all({"benefit_eligibility_element_group"=>{"applicant_status"=> ["applicant"]}})
    bc_period_for_2016.benefit_packages.update_all({"benefit_eligibility_element_group"=>{"medicaid_eligibility"=> ["non_eligible"]}})
    puts bc_period_for_2016.benefit_packages.map(&:benefit_eligibility_element_group).map(&:applicant_status).to_s
    puts bc_period_for_2016.benefit_packages.map(&:benefit_eligibility_element_group).map(&:medicaid_eligibility).to_s
    puts "2016 benefit_package update complete"

    puts "complete"
    puts "*"*80
  end

  desc "update benefit_packages ivl 2015 and 2016"
  task :ivl => :environment do
    hbx = HbxProfile.current_hbx
    bc_period_for_2016 = hbx.benefit_sponsorship.benefit_coverage_periods.select { |bcp| bcp.start_on.year == 2016 }.first
    bc_period_for_2015 = hbx.benefit_sponsorship.benefit_coverage_periods.select { |bcp| bcp.start_on.year == 2015 }.first

    ivl_health_plans_2015_for_csr_100 = Plan.individual_health_by_active_year_and_csr_kind(2015, "csr_100").entries.collect(&:_id)
    ivl_health_plans_2015_for_csr_94 = Plan.individual_health_by_active_year_and_csr_kind(2015, "csr_94").entries.collect(&:_id)
    ivl_health_plans_2015_for_csr_87 = Plan.individual_health_by_active_year_and_csr_kind(2015, "csr_87").entries.collect(&:_id)
    ivl_health_plans_2015_for_csr_73 = Plan.individual_health_by_active_year_and_csr_kind(2015, "csr_73").entries.collect(&:_id)

    individual_health_benefit_package_for_csr_100_2015 = BenefitPackage.new(
      title: "individual_health_benefits_csr_100_2015",
      elected_premium_credit_strategy: "allocated_lump_sum_credit",
      benefit_ids:          ivl_health_plans_2015_for_csr_100,
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

    individual_health_benefit_package_for_csr_94_2015 = BenefitPackage.new(
      title: "individual_health_benefits_csr_94_2015",
      elected_premium_credit_strategy: "allocated_lump_sum_credit",
      benefit_ids:          ivl_health_plans_2015_for_csr_94,
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

    individual_health_benefit_package_for_csr_87_2015 = BenefitPackage.new(
      title: "individual_health_benefits_csr_87_2015",
      elected_premium_credit_strategy: "allocated_lump_sum_credit",
      benefit_ids:          ivl_health_plans_2015_for_csr_87,
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

    individual_health_benefit_package_for_csr_73_2015 = BenefitPackage.new(
      title: "individual_health_benefits_csr_73_2015",
      elected_premium_credit_strategy: "allocated_lump_sum_credit",
      benefit_ids:          ivl_health_plans_2015_for_csr_73,
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

    bc_period_for_2015.benefit_packages << individual_health_benefit_package_for_csr_100_2015 if bc_period_for_2015.benefit_packages.where(title: "individual_health_benefits_csr_100_2015").blank?
    bc_period_for_2015.benefit_packages << individual_health_benefit_package_for_csr_94_2015 if bc_period_for_2015.benefit_packages.where(title: "individual_health_benefits_csr_94_2015").blank?
    bc_period_for_2015.benefit_packages << individual_health_benefit_package_for_csr_87_2015 if bc_period_for_2015.benefit_packages.where(title: "individual_health_benefits_csr_87_2015").blank?
    bc_period_for_2015.benefit_packages << individual_health_benefit_package_for_csr_73_2015 if bc_period_for_2015.benefit_packages.where(title: "individual_health_benefits_csr_73_2015").blank?

    bc_period_for_2015.save!
    puts "update benefit_package for 2015 successful."

    ivl_health_plans_2016_for_csr_100 = Plan.individual_health_by_active_year_and_csr_kind(2016, "csr_100").entries.collect(&:_id)
    ivl_health_plans_2016_for_csr_94 = Plan.individual_health_by_active_year_and_csr_kind(2016, "csr_94").entries.collect(&:_id)
    ivl_health_plans_2016_for_csr_87 = Plan.individual_health_by_active_year_and_csr_kind(2016, "csr_87").entries.collect(&:_id)
    ivl_health_plans_2016_for_csr_73 = Plan.individual_health_by_active_year_and_csr_kind(2016, "csr_73").entries.collect(&:_id)

    individual_health_benefit_package_for_csr_100_2016 = BenefitPackage.new(
      title: "individual_health_benefits_csr_100_2016",
      elected_premium_credit_strategy: "allocated_lump_sum_credit",
      benefit_ids:          ivl_health_plans_2016_for_csr_100,
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

    individual_health_benefit_package_for_csr_94_2016 = BenefitPackage.new(
      title: "individual_health_benefits_csr_94_2016",
      elected_premium_credit_strategy: "allocated_lump_sum_credit",
      benefit_ids:          ivl_health_plans_2016_for_csr_94,
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

    individual_health_benefit_package_for_csr_87_2016 = BenefitPackage.new(
      title: "individual_health_benefits_csr_87_2016",
      elected_premium_credit_strategy: "allocated_lump_sum_credit",
      benefit_ids:          ivl_health_plans_2016_for_csr_87,
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

    individual_health_benefit_package_for_csr_73_2016 = BenefitPackage.new(
      title: "individual_health_benefits_csr_73_2016",
      elected_premium_credit_strategy: "allocated_lump_sum_credit",
      benefit_ids:          ivl_health_plans_2016_for_csr_73,
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

    bc_period_for_2016.benefit_packages << individual_health_benefit_package_for_csr_100_2016 if bc_period_for_2016.benefit_packages.where(title: "individual_health_benefits_csr_100_2016").blank?
    bc_period_for_2016.benefit_packages << individual_health_benefit_package_for_csr_94_2016 if bc_period_for_2016.benefit_packages.where(title: "individual_health_benefits_csr_94_2016").blank?
    bc_period_for_2016.benefit_packages << individual_health_benefit_package_for_csr_87_2016 if bc_period_for_2016.benefit_packages.where(title: "individual_health_benefits_csr_87_2016").blank?
    bc_period_for_2016.benefit_packages << individual_health_benefit_package_for_csr_73_2016 if bc_period_for_2016.benefit_packages.where(title: "individual_health_benefits_csr_73_2016").blank?

    bc_period_for_2016.save!
    puts "update benefit_package for 2016 successful."
  end
end
