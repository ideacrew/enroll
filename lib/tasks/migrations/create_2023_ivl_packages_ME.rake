namespace :import do
  desc "Create 2023 benefit coverage period and packages with products"
  task :create_2023_ivl_packages_ME  => :environment do
    puts "::: Creating 2023 IVL packages :::" unless Rails.env.test?

    # BenefitPackages - HBX 2023
    hbx = HbxProfile.current_hbx

    # Second lowest cost silver plan
    slcs_products = BenefitMarkets::Products::Product.by_year(2023).where(hios_id: '54879ME0010003-01')
    slcsp_2023 =  slcs_products.select{|a| a.active_year == 2023}.first
    # check if benefit package is present for 2023
    bc_period_2023 = hbx.benefit_sponsorship.benefit_coverage_periods.select { |bcp| bcp.start_on.year == 2023 }.first

    puts 'No slcsp_2023 present' if slcsp_2023.blank?

    if bc_period_2023.present?
      if slcsp_2023.present?
        bc_period_2023.slcsp = slcsp_2023.id
        bc_period_2023.slcsp_id = slcsp_2023.id
      end
    else
      # create benefit package and benefit_coverage_period for 2023
      bc_period_2022 = hbx.benefit_sponsorship.benefit_coverage_periods.select { |bcp| bcp.start_on.year == 2022 }.first
      if bc_period_2022.blank?
        bc_period_2023 = hbx.benefit_sponsorship.benefit_coverage_periods.new
      else
        bc_period_2023 = bc_period_2022.clone
      end
      bc_period_2023.title = "Individual Market Benefits 2023"
      bc_period_2023.start_on = Date.new(2023,1,1)
      bc_period_2023.end_on = Date.new(2023,12,31)

      # if we need to change these dates after running this rake task in test or prod environments,
      # we should write a separate script.
      bc_period_2023.open_enrollment_start_on = Date.new(2022,11,1)
      bc_period_2023.open_enrollment_end_on = Date.new(2023,1,15)

      if slcsp_2023.present?
        bc_period_2023.slcsp = slcsp_2023.id
        bc_period_2023.slcsp_id = slcsp_2023.id
      end

      bc_period_2023.service_market = "individual"

      bs = hbx.benefit_sponsorship
      bs.benefit_coverage_periods << bc_period_2023
      unless bs.save
        puts 'unable to save benefits sponsorship'
        abort
      end
    end

    ivl_products = BenefitMarkets::Products::Product.aca_individual_market.with_premium_tables
    puts 'no ivl product present' if ivl_products.blank?
    abort if ivl_products.blank?

    ivl_health_plans_2023         = ivl_products.where( kind: "health", hios_id: /-01$/ ).not_in(metal_level_kind: "catastrophic").select{|a| a.active_year == 2023}.entries.collect(&:_id)
    ivl_dental_plans_2023         = ivl_products.where( kind: "dental").select{|a| a.active_year == 2023}.entries.collect(&:_id)
    ivl_and_cat_health_plans_2023 = ivl_products.where( kind: "health", hios_id: /-01$/ ).select{|a| a.active_year == 2023}.entries.collect(&:_id)
    ivl_and_cat_ni_health_plans_2023 = ivl_products.where( kind: "health", hios_id: /-01$/ ).where(metal_level_kind: "catastrophic").select{|a| a.active_year == 2023}.entries.collect(&:_id)


    individual_health_benefit_package = BenefitPackage.new(
        title: "individual_health_benefits_2023",
        elected_premium_credit_strategy: "unassisted",
        benefit_ids:          ivl_health_plans_2023,
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
        title: "individual_dental_benefits_2023",
        elected_premium_credit_strategy: "unassisted",
        benefit_ids:          ivl_dental_plans_2023,
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
        title: "catastrophic_health_benefits_2023",
        elected_premium_credit_strategy: "unassisted",
        benefit_ids:          ivl_and_cat_health_plans_2023,
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

    individual_catastrophic_ni_health_benefit_package = BenefitPackage.new(
        title: "catastrophic_health_benefits_2023",
        elected_premium_credit_strategy: "unassisted",
        benefit_ids:          ivl_and_cat_ni_health_plans_2023,
        benefit_eligibility_element_group: BenefitEligibilityElementGroup.new(
            market_places:        ["individual"],
            enrollment_periods:   ["open_enrollment", "special_enrollment"],
            family_relationships: BenefitEligibilityElementGroup::INDIVIDUAL_MARKET_RELATIONSHIP_CATEGORY_KINDS,
            benefit_categories:   ["health"],
            incarceration_status: ["unincarcerated"],
            age_range:            0..30,
            citizenship_status:   ["us_citizen", "naturalized_citizen", "alien_lawfully_present", "lawful_permanent_resident"],
            residency_status:     ["state_resident"],
            ethnicity:            ["indian_tribe_member"]
        )
    )

    native_american_health_benefit_package = BenefitPackage.new(
        title: "native_american_health_benefits_2023",
        elected_premium_credit_strategy: "unassisted",
        benefit_ids:          ivl_health_plans_2023,
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
        title: "native_american_dental_benefits_2023",
        elected_premium_credit_strategy: "unassisted",
        benefit_ids:          ivl_dental_plans_2023,
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

    ivl_health_plans_2023_for_csr_0 = ivl_products.where(
        "$and" => [
            { :kind => "health"},
            {"$or" => [
                {:metal_level_kind.in => %w(platinum gold bronze), hios_id: /-01$/ },
                {:metal_level_kind => "silver", hios_id: /-01$/ }
            ]
            }
        ]
    ).select{|a| a.active_year == 2023}.entries.collect(&:_id)

    ivl_health_plans_2023_for_csr_100 = ivl_products.where(
      "$and" => [{ :kind => 'health'},
                 {"$or" => [{:metal_level_kind.in => %w[platinum gold bronze], hios_id: /-02$/ },
                            {:metal_level_kind => 'silver', hios_id: /-02$/ }]}]
    ).select{|a| a.active_year == 2023}.entries.collect(&:_id)

    ivl_health_plans_2023_for_csr_limited = ivl_products.where(
      "$and" => [{ :kind => 'health'},
                 {"$or" => [{:metal_level_kind.in => %w[platinum gold bronze], hios_id: /-03$/ },
                            {:metal_level_kind => 'silver', hios_id: /-03$/ }]}]
    ).select{|a| a.active_year == 2023}.entries.collect(&:_id)

    ivl_health_plans_2023_for_csr_94 = ivl_products.where(
        "$and" => [
            { :kind => "health"},
            {"$or" => [
                {:metal_level_kind.in => %w(platinum gold bronze), :hios_id => /-06$/ },
                {:metal_level_kind => "silver", :hios_id => /-06$/ }
            ]
            }
        ]
    ).select{|a| a.active_year == 2023}.entries.collect(&:_id)
    ivl_health_plans_2023_for_csr_87 = ivl_products.where(
        "$and" => [
            { :kind => "health"},
            {"$or" => [
                {:metal_level_kind.in => %w(platinum gold bronze), :hios_id => /-05$/ },
                {:metal_level_kind => "silver", :hios_id => /-05$/}
            ]
            }
        ]
    ).select{|a| a.active_year == 2023}.entries.collect(&:_id)

    ivl_health_plans_2023_for_csr_73 = ivl_products.where(
        "$and" => [
            { :kind => "health"},
            {"$or" => [
                {:metal_level_kind.in => %w(platinum gold bronze), :hios_id => /-04$/ },
                {:metal_level_kind => "silver", :hios_id => /-04$/ }
            ]
            }
        ]
    ).select{|a| a.active_year == 2023}.entries.collect(&:_id)

    individual_health_benefit_package_for_csr_100 = BenefitPackage.new(
        title: "individual_health_benefits_csr_100_2023",
        elected_premium_credit_strategy: "allocated_lump_sum_credit",
        benefit_ids:          ivl_health_plans_2023_for_csr_100,
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

    individual_health_benefit_package_for_csr_0 = BenefitPackage.new(
      title: 'individual_health_benefits_csr_0_2023',
      elected_premium_credit_strategy: 'allocated_lump_sum_credit',
      benefit_ids:          ivl_health_plans_2023_for_csr_0,
      benefit_eligibility_element_group: BenefitEligibilityElementGroup.new(
        market_places:        ['individual'],
        enrollment_periods:   ['open_enrollment', 'special_enrollment'],
        family_relationships: BenefitEligibilityElementGroup::INDIVIDUAL_MARKET_RELATIONSHIP_CATEGORY_KINDS,
        benefit_categories:   ['health'],
        incarceration_status: ['unincarcerated'],
        age_range:            0..0,
        cost_sharing:         'csr_0',
        citizenship_status:   ['us_citizen', 'naturalized_citizen', 'alien_lawfully_present', 'lawful_permanent_resident'],
        residency_status:     ['state_resident'],
        ethnicity:            ['any']
      )
    )

    individual_health_benefit_package_for_csr_limited = BenefitPackage.new(
      title: 'individual_health_benefits_csr_limited_2023',
      elected_premium_credit_strategy: 'allocated_lump_sum_credit',
      benefit_ids:          ivl_health_plans_2023_for_csr_limited,
      benefit_eligibility_element_group: BenefitEligibilityElementGroup.new(
        market_places:        ['individual'],
        enrollment_periods:   ['open_enrollment', 'special_enrollment'],
        family_relationships: BenefitEligibilityElementGroup::INDIVIDUAL_MARKET_RELATIONSHIP_CATEGORY_KINDS,
        benefit_categories:   ['health'],
        incarceration_status: ['unincarcerated'],
        age_range:            0..0,
        cost_sharing:         'csr_limited',
        citizenship_status:   ['us_citizen', 'naturalized_citizen', 'alien_lawfully_present', 'lawful_permanent_resident'],
        residency_status:     ['state_resident'],
        ethnicity:            ['any']
      )
    )

    individual_health_benefit_package_for_csr_94 = BenefitPackage.new(
        title: "individual_health_benefits_csr_94_2023",
        elected_premium_credit_strategy: "allocated_lump_sum_credit",
        benefit_ids:          ivl_health_plans_2023_for_csr_94,
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
        title: "individual_health_benefits_csr_87_2023",
        elected_premium_credit_strategy: "allocated_lump_sum_credit",
        benefit_ids:          ivl_health_plans_2023_for_csr_87,
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
        title: "individual_health_benefits_csr_73_2023",
        elected_premium_credit_strategy: "allocated_lump_sum_credit",
        benefit_ids:          ivl_health_plans_2023_for_csr_73,
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

    bc_period_2023.benefit_packages = [
        individual_health_benefit_package,
        individual_dental_benefit_package,
        individual_catastrophic_health_benefit_package,
        native_american_health_benefit_package,
        native_american_dental_benefit_package,
        individual_health_benefit_package_for_csr_100,
        individual_health_benefit_package_for_csr_94,
        individual_health_benefit_package_for_csr_87,
      individual_health_benefit_package_for_csr_73,
      individual_health_benefit_package_for_csr_0,
      individual_catastrophic_ni_health_benefit_package,
      individual_health_benefit_package_for_csr_limited
    ]

    bc_period_2023.save!
  end
end
