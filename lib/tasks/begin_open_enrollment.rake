# lib/tasks/benefit_coverage.rake
namespace :benefit_coverage do
  desc 'Create a new benefit coverage period for the specified year'
  task :create_period, [:coverage_start_year, :open_enrollment_start_on, :open_enrollment_end_on] => :environment do |t, args|
    args.with_defaults(
      coverage_start_year: Date.today.year + 1,
      open_enrollment_start_on: nil,
      open_enrollment_end_on: nil
    )

    coverage_start = args.enrollment_open_date ? DateTime.parse("#{args.enrollment_open_date} 00:00:00 UTC") : DateTime.parse("#{args.coverage_start_year}-01-01 00:00:00 UTC")
    coverage_end = DateTime.parse("#{args.coverage_start_year}-12-31 00:00:00 UTC")
    open_enrollment_start_on = args.open_enrollment_start_on ? Date.parse(args.open_enrollment_start_on) : Date.yesterday
    open_enrollment_end_on = args.open_enrollment_end_on ? Date.parse(args.open_enrollment_end_on) : coverage_start

    benefit_coverage_periods = HbxProfile&.current_hbx&.benefit_sponsorship&.benefit_coverage_periods
    service_market = benefit_coverage_periods.first&.service_market
    benefit_coverage_periods.create!(
      start_on: coverage_start,
      end_on: coverage_end,
      open_enrollment_start_on: open_enrollment_start_on,
      open_enrollment_end_on: open_enrollment_end_on,
      service_market: service_market
    )

    puts 'Benefit coverage period created successfully!'
  end

  desc 'Run the specified rake tasks'
  task :run_rake_commands, [:year] => :environment do |t, args|
    args.with_defaults(year: Date.today.year + 1)
    current_env = Rails.env
    system "RAILS_ENV=#{current_env} bundle exec rake new_model:mock_data[#{args.year}]"
    system "RAILS_ENV=#{current_env} bundle exec rake migrations:update_ivl_open_enrollment_dates title='Individual Market Benefits #{args.year.pred}' new_oe_end_date='#{(Date.yesterday - 2).to_s}'"
    system "RAILS_ENV=#{current_env} bundle exec rake migrations:update_ivl_open_enrollment_dates title='Individual Market Benefits #{args.year}' new_oe_start_date='#{Date.yesterday.to_s}'"

    puts 'Rake commands executed successfully!'
  end

  desc 'Create benefit packages the specified year'
  task :create_benefit_packages, [:year] => :environment do |t, args|
    args.with_defaults(year: Date.today.year + 1)


    current_year = args.year.to_i
    puts "::: Creating #{current_year} IVL packages :::" unless Rails.env.test?

    # BenefitPackages - HBX
    hbx = HbxProfile.current_hbx
    puts hbx.blank? ? 'No current HBX present' : "Current HBX: #{hbx.us_state_abbreviation} #{hbx.cms_id}"
    abort if hbx.blank?

    bc_period_for_current_year = hbx.benefit_sponsorship.benefit_coverage_periods.select { |bcp| bcp.start_on.year == current_year }.first
    slcsp_id = bc_period_for_current_year&.slcsp_id
    slcsp_hios_id = BenefitMarkets::Products::Product.where(id: slcsp_id)&.first&.hios_id ||
      hbx.us_state_abbreviation == 'ME' ? '96667ME0310072-03' : '94506DC0390005-01'
    slcs_products = BenefitMarkets::Products::Product.where(hios_id: slcsp_hios_id)
    slcsp_for_current_year =  slcs_products.select{|a| a.active_year == current_year}.first
    bc_period_for_current_year.slcsp = slcsp_for_current_year.id
    bc_period_for_current_year.slcsp_id = slcsp_for_current_year.id
    ivl_products = BenefitMarkets::Products::Product.aca_individual_market
    ivl_health_plans_for_current_year         = ivl_products.where( kind: 'health', hios_id: /-01$/ ).not_in(metal_level_kind: 'catastrophic').select{|a| a.active_year == current_year}.entries.collect(&:_id)
    ivl_dental_plans_for_current_year         = ivl_products.where( kind: 'dental').select{|a| a.active_year == current_year}.entries.collect(&:_id)
    ivl_and_cat_health_plans_for_current_year = ivl_products.where( kind: 'health', hios_id: /-01$/ ).select{|a| a.active_year == current_year}.entries.collect(&:_id)

    individual_health_benefit_package = BenefitPackage.new(
      title: "individual_health_benefits_#{current_year}",
      elected_premium_credit_strategy: 'unassisted',
      benefit_ids:          ivl_health_plans_for_current_year,
      benefit_eligibility_element_group: BenefitEligibilityElementGroup.new(
        market_places:        ['individual'],
        enrollment_periods:   ['open_enrollment', 'special_enrollment'],
        family_relationships: BenefitEligibilityElementGroup::INDIVIDUAL_MARKET_RELATIONSHIP_CATEGORY_KINDS,
        benefit_categories:   ['health'],
        incarceration_status: ['unincarcerated'],
        age_range:            0..0,
        citizenship_status:   ['us_citizen', 'naturalized_citizen', 'alien_lawfully_present', 'lawful_permanent_resident'],
        residency_status:     ['state_resident'],
        ethnicity:            ['any']
      )
    )

    individual_dental_benefit_package = BenefitPackage.new(
      title: "individual_dental_benefits_#{current_year}",
      elected_premium_credit_strategy: 'unassisted',
      benefit_ids:          ivl_dental_plans_for_current_year,
      benefit_eligibility_element_group: BenefitEligibilityElementGroup.new(
        market_places:        ['individual'],
        enrollment_periods:   ['open_enrollment', 'special_enrollment'],
        family_relationships: BenefitEligibilityElementGroup::INDIVIDUAL_MARKET_RELATIONSHIP_CATEGORY_KINDS,
        benefit_categories:   ['dental'],
        incarceration_status: ['unincarcerated'],
        age_range:            0..0,
        citizenship_status:   ['us_citizen', 'naturalized_citizen', 'alien_lawfully_present', 'lawful_permanent_resident'],
        residency_status:     ['state_resident'],
        ethnicity:            ['any']
      )
    )

    individual_catastrophic_health_benefit_package = BenefitPackage.new(
      title: "catastrophic_health_benefits_#{current_year}",
      elected_premium_credit_strategy: 'unassisted',
      benefit_ids:          ivl_and_cat_health_plans_for_current_year,
      benefit_eligibility_element_group: BenefitEligibilityElementGroup.new(
        market_places:        ['individual'],
        enrollment_periods:   ['open_enrollment', 'special_enrollment'],
        family_relationships: BenefitEligibilityElementGroup::INDIVIDUAL_MARKET_RELATIONSHIP_CATEGORY_KINDS,
        benefit_categories:   ['health'],
        incarceration_status: ['unincarcerated'],
        age_range:            0..30,
        citizenship_status:   ['us_citizen', 'naturalized_citizen', 'alien_lawfully_present', 'lawful_permanent_resident'],
        residency_status:     ['state_resident'],
        ethnicity:            ['any']
      )
    )

    native_american_health_benefit_package = BenefitPackage.new(
      title: "native_american_health_benefits_#{current_year}",
      elected_premium_credit_strategy: 'unassisted',
      benefit_ids:          ivl_health_plans_for_current_year,
      benefit_eligibility_element_group: BenefitEligibilityElementGroup.new(
        market_places:        ['individual'],
        enrollment_periods:   ['open_enrollment', 'special_enrollment'],
        family_relationships: BenefitEligibilityElementGroup::INDIVIDUAL_MARKET_RELATIONSHIP_CATEGORY_KINDS,
        benefit_categories:   ['health'],
        incarceration_status: ['unincarcerated'],
        age_range:            0..0,
        citizenship_status:   ['us_citizen', 'naturalized_citizen', 'alien_lawfully_present', 'lawful_permanent_resident'],
        residency_status:     ['state_resident'],
        ethnicity:            ['indian_tribe_member']
      )
    )

    native_american_dental_benefit_package = BenefitPackage.new(
      title: "native_american_dental_benefits_#{current_year}",
      elected_premium_credit_strategy: 'unassisted',
      benefit_ids:          ivl_dental_plans_for_current_year,
      benefit_eligibility_element_group: BenefitEligibilityElementGroup.new(
        market_places:        ['individual'],
        enrollment_periods:   ['any'],
        family_relationships: BenefitEligibilityElementGroup::INDIVIDUAL_MARKET_RELATIONSHIP_CATEGORY_KINDS,
        benefit_categories:   ['dental'],
        incarceration_status: ['unincarcerated'],
        age_range:            0..0,
        citizenship_status:   ['us_citizen', 'naturalized_citizen', 'alien_lawfully_present', 'lawful_permanent_resident'],
        residency_status:     ['state_resident'],
        ethnicity:            ['indian_tribe_member']
      )
    )

    ivl_health_plans_for_current_year_for_csr_0 = ivl_products.where(
      '$and' => [
        { :kind => 'health'},
        {'$or' => [
          {:metal_level_kind.in => %w(platinum gold bronze), hios_id: /-01$/ },
          {:metal_level_kind => 'silver', hios_id: /-01$/ }
        ]
        }
      ]
    ).select{|a| a.active_year == current_year}.entries.collect(&:_id)

    ivl_health_plans_for_current_year_for_csr_100 = ivl_products.where(
      '$and' => [{ :kind => 'health'},
                 {'$or' => [{:metal_level_kind.in => %w[platinum gold bronze], hios_id: /-02$/ },
                            {:metal_level_kind => 'silver', hios_id: /-02$/ }]}]
    ).select{|a| a.active_year == current_year}.entries.collect(&:_id)

    ivl_health_plans_for_current_year_for_csr_limited = ivl_products.where(
      '$and' => [{ :kind => 'health'},
                 {'$or' => [{:metal_level_kind.in => %w[platinum gold bronze], hios_id: /-03$/ },
                            {:metal_level_kind => 'silver', hios_id: /-03$/ }]}]
    ).select{|a| a.active_year == current_year}.entries.collect(&:_id)

    ivl_health_plans_for_current_year_for_csr_94 = ivl_products.where(
      '$and' => [
        { :kind => 'health'},
        {'$or' => [
          {:metal_level_kind.in => %w(platinum gold bronze), :hios_id => /-06$/ },
          {:metal_level_kind => 'silver', :hios_id => /-06$/ }
        ]
        }
      ]
    ).select{|a| a.active_year == current_year}.entries.collect(&:_id)
    ivl_health_plans_for_current_year_for_csr_87 = ivl_products.where(
      '$and' => [
        { :kind => 'health'},
        {'$or' => [
          {:metal_level_kind.in => %w(platinum gold bronze), :hios_id => /-05$/ },
          {:metal_level_kind => 'silver', :hios_id => /-05$/}
        ]
        }
      ]
    ).select{|a| a.active_year == current_year}.entries.collect(&:_id)

    ivl_health_plans_for_current_year_for_csr_73 = ivl_products.where(
      '$and' => [
        { :kind => 'health'},
        {'$or' => [
          {:metal_level_kind.in => %w(platinum gold bronze), :hios_id => /-04$/ },
          {:metal_level_kind => 'silver', :hios_id => /-04$/ }
        ]
        }
      ]
    ).select{|a| a.active_year == current_year}.entries.collect(&:_id)

    individual_health_benefit_package_for_csr_100 = BenefitPackage.new(
      title: "individual_health_benefits_csr_100_#{current_year}",
      elected_premium_credit_strategy: 'allocated_lump_sum_credit',
      benefit_ids:          ivl_health_plans_for_current_year_for_csr_100,
      benefit_eligibility_element_group: BenefitEligibilityElementGroup.new(
        market_places:        ['individual'],
        enrollment_periods:   ['open_enrollment', 'special_enrollment'],
        family_relationships: BenefitEligibilityElementGroup::INDIVIDUAL_MARKET_RELATIONSHIP_CATEGORY_KINDS,
        benefit_categories:   ['health'],
        incarceration_status: ['unincarcerated'],
        age_range:            0..0,
        cost_sharing:         'csr_100',
        citizenship_status:   ['us_citizen', 'naturalized_citizen', 'alien_lawfully_present', 'lawful_permanent_resident'],
        residency_status:     ['state_resident'],
        ethnicity:            ['any']
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
      elected_premium_credit_strategy: 'allocated_lump_sum_credit',
      benefit_ids:          ivl_health_plans_for_current_year_for_csr_94,
      benefit_eligibility_element_group: BenefitEligibilityElementGroup.new(
        market_places:        ['individual'],
        enrollment_periods:   ['open_enrollment', 'special_enrollment'],
        family_relationships: BenefitEligibilityElementGroup::INDIVIDUAL_MARKET_RELATIONSHIP_CATEGORY_KINDS,
        benefit_categories:   ['health'],
        incarceration_status: ['unincarcerated'],
        age_range:            0..0,
        cost_sharing:         'csr_94',
        citizenship_status:   ['us_citizen', 'naturalized_citizen', 'alien_lawfully_present', 'lawful_permanent_resident'],
        residency_status:     ['state_resident'],
        ethnicity:            ['any']
      )
    )

    individual_health_benefit_package_for_csr_87 = BenefitPackage.new(
      title: "individual_health_benefits_csr_87_#{current_year}",
      elected_premium_credit_strategy: 'allocated_lump_sum_credit',
      benefit_ids:          ivl_health_plans_for_current_year_for_csr_87,
      benefit_eligibility_element_group: BenefitEligibilityElementGroup.new(
        market_places:        ['individual'],
        enrollment_periods:   ['open_enrollment', 'special_enrollment'],
        family_relationships: BenefitEligibilityElementGroup::INDIVIDUAL_MARKET_RELATIONSHIP_CATEGORY_KINDS,
        benefit_categories:   ['health'],
        incarceration_status: ['unincarcerated'],
        age_range:            0..0,
        cost_sharing:         'csr_87',
        citizenship_status:   ['us_citizen', 'naturalized_citizen', 'alien_lawfully_present', 'lawful_permanent_resident'],
        residency_status:     ['state_resident'],
        ethnicity:            ['any']
      )
    )

    individual_health_benefit_package_for_csr_73 = BenefitPackage.new(
      title: "individual_health_benefits_csr_73_#{current_year}",
      elected_premium_credit_strategy: 'allocated_lump_sum_credit',
      benefit_ids:          ivl_health_plans_for_current_year_for_csr_73,
      benefit_eligibility_element_group: BenefitEligibilityElementGroup.new(
        market_places:        ['individual'],
        enrollment_periods:   ['open_enrollment', 'special_enrollment'],
        family_relationships: BenefitEligibilityElementGroup::INDIVIDUAL_MARKET_RELATIONSHIP_CATEGORY_KINDS,
        benefit_categories:   ['health'],
        incarceration_status: ['unincarcerated'],
        age_range:            0..0,
        cost_sharing:         'csr_73',
        citizenship_status:   ['us_citizen', 'naturalized_citizen', 'alien_lawfully_present', 'lawful_permanent_resident'],
        residency_status:     ['state_resident'],
        ethnicity:            ['any']
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

  # Usage:
  # RAILS_ENV=production bundle exec rake benefit_coverage:run_all
  desc 'Run all tasks sequentially'
  task run_all: [:create_period, :run_rake_commands, :create_benefit_packages]
end