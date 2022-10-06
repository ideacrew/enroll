# This rake is not for mock plans

namespace :import do
  desc "Create current year benefit coverage period and packages with products"
  task :create_ivl_benefit_packages_DC  => :environment do
    puts "::: Creating IVL packages :::" unless Rails.env.test?

    # BenefitPackages - HBX 2023
    hbx = HbxProfile.current_hbx
    puts 'No current HBX present' if hbx.blank?
    abort if hbx.blank?

    raise "please pass year" unless ENV['year'].present?

    year = ENV['year'].to_i

    # Second lowest cost silver plan
    slcs_products = BenefitMarkets::Products::Product.where(hios_id: "94506DC0390006-01")
    current_slcsp =  slcs_products.select{|a| a.active_year == year}.first
    # check if benefit package is present for 2023
    current_period_bc = hbx.benefit_sponsorship.benefit_coverage_periods.select { |bcp| bcp.start_on.year == year }.first

    puts 'No current_slcsp present' if current_slcsp.blank?
    abort if current_slcsp.blank?

    if current_period_bc.present?
      current_period_bc.slcsp = current_slcsp.id
      current_period_bc.slcsp_id = current_slcsp.id
    else
      # create benefit package and benefit_coverage_period for 2023
      previous_period_bc = hbx.benefit_sponsorship.benefit_coverage_periods.select { |bcp| bcp.start_on.year == year.pred }.first
      current_period_bc = previous_period_bc.clone
      current_period_bc.title = "Individual Market Benefits #{year}"
      current_period_bc.start_on = previous_period_bc.start_on + 1.year
      current_period_bc.end_on = previous_period_bc.end_on + 1.year

      # if we need to change these dates after running this rake task in test or prod environments,
      # we should write a separate script.
      current_period_bc.open_enrollment_start_on = Date.new(year.pred,11,1)
      current_period_bc.open_enrollment_end_on = Date.new(year,1,31)

      current_period_bc.slcsp = current_slcsp.id
      current_period_bc.slcsp_id = current_slcsp.id

      bs = hbx.benefit_sponsorship
      bs.benefit_coverage_periods << current_period_bc
      unless bs.save
        puts 'unable to save benefits sponsorship'
        abort
      end
    end

    ivl_products = BenefitMarkets::Products::Product.by_year(year).aca_individual_market.with_premium_tables
    puts 'no ivl product present' if ivl_products.blank?
    abort if ivl_products.blank?

    current_ivl_health_plans         = ivl_products.where( kind: "health", hios_id: /-01$/ ).not_in(metal_level_kind: "catastrophic").pluck(:_id)
    current_ivl_dental_plans         = ivl_products.where( kind: "dental").pluck(:_id)
    current_ivl_and_cat_health_plans = ivl_products.where( kind: "health", hios_id: /-01$/ ).pluck(:_id)


    individual_health_benefit_package = BenefitPackage.new(
        title: "individual_health_benefits_#{year}",
        elected_premium_credit_strategy: "unassisted",
        benefit_ids:          current_ivl_health_plans,
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
        title: "individual_dental_benefits_#{year}",
        elected_premium_credit_strategy: "unassisted",
        benefit_ids:          current_ivl_dental_plans,
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
        title: "catastrophic_health_benefits_#{year}",
        elected_premium_credit_strategy: "unassisted",
        benefit_ids:          current_ivl_and_cat_health_plans,
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
        title: "native_american_health_benefits_#{year}",
        elected_premium_credit_strategy: "unassisted",
        benefit_ids:          current_ivl_health_plans,
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
        title: "native_american_dental_benefits_#{year}",
        elected_premium_credit_strategy: "unassisted",
        benefit_ids:          current_ivl_dental_plans,
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

    current_ivl_health_plans_for_csr_0 = ivl_products.where(
        "$and" => [
            { :kind => "health"},
            {"$or" => [
                {:metal_level_kind.in => %w(platinum gold bronze), hios_id: /-01$/ },
                {:metal_level_kind => "silver", hios_id: /-01$/ }
            ]
            }
        ]
    ).pluck(:_id)

    current_ivl_health_plans_for_csr_100 = ivl_products.where(
      "$and" => [{ :kind => 'health'},
                 {"$or" => [{:metal_level_kind.in => %w[platinum gold bronze], hios_id: /-02$/ },
                            {:metal_level_kind => 'silver', hios_id: /-02$/ }]}]
    ).pluck(:_id)

    current_ivl_health_plans_for_csr_limited = ivl_products.where(
      "$and" => [{ :kind => 'health'},
                 {"$or" => [{:metal_level_kind.in => %w[platinum gold bronze], hios_id: /-03$/ },
                            {:metal_level_kind => 'silver', hios_id: /-03$/ }]}]
    ).pluck(:_id)

    current_ivl_health_plans_for_csr_94 = ivl_products.where(
        "$and" => [
            { :kind => "health"},
            {"$or" => [
                {:metal_level_kind.in => %w(platinum gold bronze), :hios_id => /-06$/ },
                {:metal_level_kind => "silver", :hios_id => /-06$/ }
            ]
            }
        ]
    ).pluck(:_id)
    current_ivl_health_plans_for_csr_87 = ivl_products.where(
        "$and" => [
            { :kind => "health"},
            {"$or" => [
                {:metal_level_kind.in => %w(platinum gold bronze), :hios_id => /-05$/ },
                {:metal_level_kind => "silver", :hios_id => /-05$/}
            ]
            }
        ]
    ).pluck(:_id)

    current_ivl_health_plans_for_csr_73 = ivl_products.where(
        "$and" => [
            { :kind => "health"},
            {"$or" => [
                {:metal_level_kind.in => %w(platinum gold bronze), :hios_id => /-04$/ },
                {:metal_level_kind => "silver", :hios_id => /-04$/ }
            ]
            }
        ]
    ).pluck(:_id)

    individual_health_benefit_package_for_csr_100 = BenefitPackage.new(
        title: "individual_health_benefits_csr_100_#{year}",
        elected_premium_credit_strategy: "allocated_lump_sum_credit",
        benefit_ids:          current_ivl_health_plans_for_csr_100,
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
      title: 'individual_health_benefits_csr_0_#{year}',
      elected_premium_credit_strategy: 'allocated_lump_sum_credit',
      benefit_ids:          current_ivl_health_plans_for_csr_0,
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
      title: 'individual_health_benefits_csr_limited_#{year}',
      elected_premium_credit_strategy: 'allocated_lump_sum_credit',
      benefit_ids:          current_ivl_health_plans_for_csr_limited,
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
        title: "individual_health_benefits_csr_94_#{year}",
        elected_premium_credit_strategy: "allocated_lump_sum_credit",
        benefit_ids:          current_ivl_health_plans_for_csr_94,
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
        title: "individual_health_benefits_csr_87_#{year}",
        elected_premium_credit_strategy: "allocated_lump_sum_credit",
        benefit_ids:          current_ivl_health_plans_for_csr_87,
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
        title: "individual_health_benefits_csr_73_#{year}",
        elected_premium_credit_strategy: "allocated_lump_sum_credit",
        benefit_ids:          current_ivl_health_plans_for_csr_73,
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

    current_period_bc.benefit_packages = [
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

    current_period_bc.save!
  end
end
