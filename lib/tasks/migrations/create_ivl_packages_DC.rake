namespace :import do
  desc "Create benefit coverage period and packages with products"
  task :create_ivl_packages_DC, [:active_year] => :environment do |t, args|
    current_year = args[:active_year]

    raise "no year given as arguments in rake task, example: bundle exec rake import:create_ivl_packages_DC[2010]" and return if current_year.blank?

    previous_year = current_year - 1
    puts "::: Creating #{current_year} IVL packages :::" unless Rails.env.test?

    # BenefitPackages - HBX
    hbx = HbxProfile.current_hbx
    puts 'No current HBX present' if hbx.blank?
    abort if hbx.blank?

    #
    # check if benefit package is present
    #
    bc_period_for_current_year = hbx.benefit_sponsorship.benefit_coverage_periods.select { |bcp| bcp.start_on.year == current_year }.first

    #
    # Second lowest cost silver plan
    #
    slcsp_id = bc_period_for_current_year.slcsp_id
    slcsp_hios_id = BenefitMarkets::Products::Product.where(id: slcsp_id).first&.hios_id || "94506DC0390005-01"
    slcs_products = BenefitMarkets::Products::Product.where(hios_id: slcsp_hios_id)
    slcsp_for_current_year =  slcs_products.select{|a| a.active_year == current_year}.first

    puts 'No slcsp_for_current_year present' if slcsp_for_current_year.blank?
    abort if slcsp_for_current_year.blank?

    if bc_period_for_current_year.present?
      bc_period_for_current_year.slcsp = slcsp_for_current_year.id
      bc_period_for_current_year.slcsp_id = slcsp_for_current_year.id
    else
      # create benefit package and benefit_coverage_period
      bc_period_for_previous_year = hbx.benefit_sponsorship.benefit_coverage_periods.select { |bcp| bcp.start_on.year == previous_year }.first
      bc_period_for_current_year = bc_period_for_previous_year.clone
      bc_period_for_current_year.title = "Individual Market Benefits #{current_year}"
      bc_period_for_current_year.start_on = bc_period_for_previous_year.start_on + 1.year
      bc_period_for_current_year.end_on = bc_period_for_previous_year.end_on + 1.year

      # if we need to change these dates after running this rake task in test or prod environments,
      # we should write a separate script.
      bc_period_for_current_year.open_enrollment_start_on = Date.new(previous_year,11,1)
      bc_period_for_current_year.open_enrollment_end_on = Date.new(current_year,1,31)

      bc_period_for_current_year.slcsp = slcsp_for_current_year.id
      bc_period_for_current_year.slcsp_id = slcsp_for_current_year.id

      bs = hbx.benefit_sponsorship
      bs.benefit_coverage_periods << bc_period_for_current_year
      unless bs.save
        puts 'unable to save benefits sponsorship'
        abort
      end
    end

    ivl_products = BenefitMarkets::Products::Product.aca_individual_market
    puts 'no ivl product present' if ivl_products.blank?
    abort if ivl_products.blank?

    ivl_health_plans_for_current_year         = ivl_products.where( kind: "health", hios_id: /-01$/ ).not_in(metal_level_kind: "catastrophic").select{|a| a.active_year == current_year}.entries.collect(&:_id)
    ivl_dental_plans_for_current_year         = ivl_products.where( kind: "dental").select{|a| a.active_year == current_year}.entries.collect(&:_id)
    ivl_and_cat_health_plans_for_current_year = ivl_products.where( kind: "health", hios_id: /-01$/ ).select{|a| a.active_year == current_year}.entries.collect(&:_id)


    individual_health_benefit_package = BenefitPackage.new(
        title: "individual_health_benefits_#{current_year}",
        elected_premium_credit_strategy: "unassisted",
        benefit_ids:          ivl_health_plans_for_current_year,
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
        title: "individual_dental_benefits_#{current_year}",
        elected_premium_credit_strategy: "unassisted",
        benefit_ids:          ivl_dental_plans_for_current_year,
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
        title: "catastrophic_health_benefits_#{current_year}",
        elected_premium_credit_strategy: "unassisted",
        benefit_ids:          ivl_and_cat_health_plans_for_current_year,
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
        title: "native_american_health_benefits_#{current_year}",
        elected_premium_credit_strategy: "unassisted",
        benefit_ids:          ivl_health_plans_for_current_year,
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
        title: "native_american_dental_benefits_#{current_year}",
        elected_premium_credit_strategy: "unassisted",
        benefit_ids:          ivl_dental_plans_for_current_year,
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

    ivl_health_plans_for_current_year_for_csr_0 = ivl_products.where(
        "$and" => [
            { :kind => "health"},
            {"$or" => [
                {:metal_level_kind.in => %w(platinum gold bronze), hios_id: /-01$/ },
                {:metal_level_kind => "silver", hios_id: /-01$/ }
            ]
            }
        ]
    ).select{|a| a.active_year == current_year}.entries.collect(&:_id)

    ivl_health_plans_for_current_year_for_csr_100 = ivl_products.where(
      "$and" => [{ :kind => 'health'},
                 {"$or" => [{:metal_level_kind.in => %w[platinum gold bronze], hios_id: /-02$/ },
                            {:metal_level_kind => 'silver', hios_id: /-02$/ }]}]
    ).select{|a| a.active_year == current_year}.entries.collect(&:_id)

    ivl_health_plans_for_current_year_for_csr_limited = ivl_products.where(
      "$and" => [{ :kind => 'health'},
                 {"$or" => [{:metal_level_kind.in => %w[platinum gold bronze], hios_id: /-03$/ },
                            {:metal_level_kind => 'silver', hios_id: /-03$/ }]}]
    ).select{|a| a.active_year == current_year}.entries.collect(&:_id)

    ivl_health_plans_for_current_year_for_csr_94 = ivl_products.where(
        "$and" => [
            { :kind => "health"},
            {"$or" => [
                {:metal_level_kind.in => %w(platinum gold bronze), :hios_id => /-06$/ },
                {:metal_level_kind => "silver", :hios_id => /-06$/ }
            ]
            }
        ]
    ).select{|a| a.active_year == current_year}.entries.collect(&:_id)
    ivl_health_plans_for_current_year_for_csr_87 = ivl_products.where(
        "$and" => [
            { :kind => "health"},
            {"$or" => [
                {:metal_level_kind.in => %w(platinum gold bronze), :hios_id => /-05$/ },
                {:metal_level_kind => "silver", :hios_id => /-05$/}
            ]
            }
        ]
    ).select{|a| a.active_year == current_year}.entries.collect(&:_id)

    ivl_health_plans_for_current_year_for_csr_73 = ivl_products.where(
        "$and" => [
            { :kind => "health"},
            {"$or" => [
                {:metal_level_kind.in => %w(platinum gold bronze), :hios_id => /-04$/ },
                {:metal_level_kind => "silver", :hios_id => /-04$/ }
            ]
            }
        ]
    ).select{|a| a.active_year == current_year}.entries.collect(&:_id)

    individual_health_benefit_package_for_csr_100 = BenefitPackage.new(
        title: "individual_health_benefits_csr_100_#{current_year}",
        elected_premium_credit_strategy: "allocated_lump_sum_credit",
        benefit_ids:          ivl_health_plans_for_current_year_for_csr_100,
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
      title: 'individual_health_benefits_csr_0_#{current_year}',
      elected_premium_credit_strategy: 'allocated_lump_sum_credit',
      benefit_ids:          ivl_health_plans_for_current_year_for_csr_0,
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
      title: 'individual_health_benefits_csr_limited_#{current_year}',
      elected_premium_credit_strategy: 'allocated_lump_sum_credit',
      benefit_ids:          ivl_health_plans_for_current_year_for_csr_limited,
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
        title: "individual_health_benefits_csr_94_#{current_year}",
        elected_premium_credit_strategy: "allocated_lump_sum_credit",
        benefit_ids:          ivl_health_plans_for_current_year_for_csr_94,
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
        title: "individual_health_benefits_csr_87_#{current_year}",
        elected_premium_credit_strategy: "allocated_lump_sum_credit",
        benefit_ids:          ivl_health_plans_for_current_year_for_csr_87,
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
        title: "individual_health_benefits_csr_73_#{current_year}",
        elected_premium_credit_strategy: "allocated_lump_sum_credit",
        benefit_ids:          ivl_health_plans_for_current_year_for_csr_73,
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

    bc_period_for_current_year.benefit_packages = [
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
      individual_health_benefit_package_for_csr_limited
    ]

    bc_period_for_current_year.save!
  end
end
