namespace :dry_run do
  namespace :data do
    desc "refresh the database for a given year"
    task :refresh_database, [:year] => :environment do |_t, args|
      year = args[:year].to_i
      Rake::Task['dry_run:data:remove_all'].invoke(year)
      Rake::Task['dry_run:data:create_all'].invoke(year)
    end

    desc "create all data for a given year"
    task :create_all, [:year] => :environment do |_t, args|
      year = args[:year].to_i
      Rake::Task['dry_run:data:create_service_areas'].invoke(year)
      Rake::Task['dry_run:data:create_rating_areas'].invoke(year)
      Rake::Task['dry_run:data:create_actuarial_factors'].invoke(year)
      Rake::Task['dry_run:data:create_products'].invoke(year)
      Rake::Task['dry_run:data:create_benefit_coverage_period'].invoke(year)
      Rake::Task['dry_run:data:create_benefit_market_catalogs'].invoke(year)
      Rake::Task['dry_run:data:create_mappings'].invoke(year)
    end

    desc "remove all data for a given year"
    task :remove_all, [:year] => :environment do |_t, args|
      year = args[:year].to_i
      Rake::Task['dry_run:data:remove_service_areas'].invoke(year)
      Rake::Task['dry_run:data:remove_rating_areas'].invoke(year)
      Rake::Task['dry_run:data:remove_actuarial_factors'].invoke(year)
      Rake::Task['dry_run:data:remove_products'].invoke(year)
      Rake::Task['dry_run:data:remove_benefit_coverage_periods'].invoke(year)
      Rake::Task['dry_run:data:remove_benefit_market_catalogs'].invoke(year)
      Rake::Task['dry_run:data:remove_mappings'].invoke(year)
      Rake::Task['dry_run:data:remove_financial_assistance_applications'].invoke(year)
    end

    desc "create service areas for a given year"
    task :create_service_areas, [:year] => :environment do |_t, args|
      ::BenefitSponsors::Organizations::Organization.issuer_profiles.each do |issuer_organization|
        issuer_profile = issuer_organization.issuer_profile
        issuer_profile.issuer_hios_ids.each do |issuer_hios_id|
          ::BenefitMarkets::Locations::ServiceArea.find_or_create_by!({
                                                                        active_year: args[:year].to_i,
                                                                        issuer_provided_code: EnrollRegistry[:issuer_provided_code].item,
                                                                        covered_states: [EnrollRegistry[:enroll_app].setting(:state_abbreviation)&.item],
                                                                        county_zip_ids: [], #@todo: add county_zip_ids
                                                                        issuer_profile_id: issuer_profile.id,
                                                                        issuer_hios_id: issuer_hios_id,
                                                                        issuer_provided_title: issuer_profile.legal_name
                                                                      })
        end
      end
    end

    desc "remove service areas for a given year"
    task :remove_service_areas, [:year] => :environment do |_t, args|
      ::BenefitMarkets::Locations::ServiceArea.where(active_year: args[:year].to_i).delete_all
    end

    desc "create rating areas for a given year"
    task :create_rating_areas, [:year] => :environment do |_t, args|
      ::BenefitMarkets::Locations::RatingArea.find_or_create_by!({
                                                                   active_year: args[:year].to_i,
                                                                   exchange_provided_code: EnrollRegistry[:exchange_provided_code].item,
                                                                   county_zip_ids: [], #@todo: add county_zip_ids
                                                                   covered_states: [EnrollRegistry[:enroll_app].setting(:state_abbreviation)&.item]
                                                                 })
    end

    desc "remove rating areas for a given year"
    task :remove_rating_areas, [:year] => :environment do |_t, args|
      ::BenefitMarkets::Locations::RatingArea.where(active_year: args[:year].to_i).delete_all
    end

    desc "create products and plans for a given year"
    task :create_products_and_plans, [:year] => :environment do |_t, args|
      year = args[:year]
      previous_year = year - 1
      rating_area = ::BenefitMarkets::Locations::RatingArea.where(active_year: year).first

      ::BenefitMarkets::Products::Product.by_year(previous_year).each do |product|
        new_service_area = ::BenefitMarkets::Locations::ServiceArea.where(
          active_year: year,
          issuer_profile_id: product.issuer_profile_id
        ).first

        next if ::BenefitMarkets::Products::Product.by_year(year).where(hios_id: product.hios_id, benefit_market_kind: product.benefit_market_kind).present?

        new_product = product.dup
        new_product.application_period = (product.application_period.min + 1.year..product.application_period.max + 1.year)
        new_product.service_area_id = new_service_area.id
        new_product.premium_tables.each do |new_premium_table|
          new_premium_table.effective_period = (new_premium_table.effective_period.min + 1.year..new_premium_table.effective_period.max + 1.year)
          new_premium_table.rating_area_id = rating_area.id
        end
        new_product.save
      end

      ::Plan.by_active_year(previous_year).each do |plan|
        new_service_area = ::BenefitMarkets::Locations::ServiceArea.where(
          active_year: year,
          issuer_profile_id: plan.carrier_profile_id
        ).first

        next if ::Plan.where(active_year: year, hios_id: plan.hios_id, market: plan.market).present?

        new_plan = plan.dup
        new_plan.active_year = year
        new_plan.service_area_id =
          if new_service_area.nil?
            site_key = EnrollRegistry[:enroll_app].setting(:site_key).item
            "#{site_key.upcase}S002" # @todo: is this client specific?
          else
            new_service_area.issuer_provided_code
          end
        new_plan.premium_tables.each do |new_premium_table|
          new_premium_table.start_on = new_premium_table.start_on.next_year
          new_premium_table.end_on = new_premium_table.end_on.next_year
          new_premium_table.rating_area = rating_area.exchange_provided_code
        end

        new_plan.save
      end
    end

    desc "remove products and plans for a given year"
    task :remove_products_and_plans, [:year] => :environment do |_t, args|
      ::BenefitMarkets::Products::Product.by_year(args[:year].to_i).delete_all
      ::Plan.by_active_year(args[:year].to_i).delete_all
    end

    desc "create actuarial factors for a given year"
    task :create_actuarial_factors, [:year] => :environment do |_t, args|
      year = args[:year].to_i
      ::BenefitSponsors::Organizations::Organization.issuer_profiles.each do |issuer_organization|
        issuer_profile = issuer_organization.issuer_profile
        ::BenefitMarkets::Products::ActuarialFactors::ParticipationRateActuarialFactor.find_or_create_by!(
          active_year: year,
          default_factor_value: 1.0,
          max_integer_factor_key: 100,
          issuer_profile_id: issuer_profile.id,
          actuarial_factor_entries: []
        )
        ::BenefitMarkets::Products::ActuarialFactors::GroupSizeActuarialFactor.find_or_create_by!(
          active_year: year,
          default_factor_value: 1.0,
          max_integer_factor_key: 1,
          issuer_profile_id: issuer_profile.id,
          actuarial_factor_entries: []
        )
      end
    end

    desc "remove actuarial factors for a given year"
    task :remove_actuarial_factors, [:year] => :environment do |_t, args|
      ::BenefitMarkets::Products::ActuarialFactors::ParticipationRateActuarialFactor.where(active_year: args[:year].to_i).delete_all
      ::BenefitMarkets::Products::ActuarialFactors::GroupSizeActuarialFactor.where(active_year: args[:year].to_i).delete_all
    end

    # @todo: this task comes from load_dc_benefit_market_catalog.rake it may be specific to DC. What is benefit market catalog?
    desc "create benefit market catalogs for a given year"
    task :create_benefit_market_catalogs, [:year] => :environment do |_t, args|
      year = args[:year].to_i
      health_product_kinds = [:metal_level, :single_product, :single_issuer]
      dental_product_kinds = [:multi_product, :single_issuer]
      market_kinds = []
      market_kinds << :aca_shop if EnrollRegistry.feature_enabled?(:aca_shop_market)
      market_kinds << :fehb if EnrollRegistry.feature_enabled?(:fehb_market)
      market_kinds.each do |kind|
        benefit_market = BenefitMarkets::BenefitMarket.where(:site_urn => EnrollRegistry[:enroll_app].setting(:site_key).item, kind: kind).first
        benefit_market_catalog = benefit_market.benefit_market_catalogs.select {
          |a| a.application_period.first.year.to_s == year.to_s
        }.first
        benefit_market_catalog ||= benefit_market.benefit_market_catalogs.create!({
                                                                                    title: "#{Settings.aca.state_abbreviation} #{EnrollRegistry[:enroll_app].setting(:short_name).item} SHOP Benefit Catalog",
                                                                                    application_interval_kind: :monthly,
                                                                                    application_period: Date.new(year, 1, 1)..Date.new(year, 12, 31),
                                                                                    probation_period_kinds: ::BenefitMarkets::PROBATION_PERIOD_KINDS
                                                                                  })

        congress_contribution_model = BenefitMarkets::ContributionModels::ContributionModel.where(title: "DC Congress Contribution Model").first.create_copy_for_embedding
        shop_contribution_model = BenefitMarkets::ContributionModels::ContributionModel.where(title: "DC Shop Simple List Bill Contribution Model").first.create_copy_for_embedding
        contribution_model = kind.to_s == "aca_shop" ? shop_contribution_model : congress_contribution_model
        pricing_model = BenefitMarkets::PricingModels::PricingModel.where(:name => "DC Shop Simple List Bill Pricing Model").first.create_copy_for_embedding

        def products_for(product_package, year)
          product_class = product_package.product_kind.to_s == "health" ? BenefitMarkets::Products::HealthProducts::HealthProduct : BenefitMarkets::Products::DentalProducts::DentalProduct
          product_class.by_product_package(product_package).collect { |prod| prod.create_copy_for_embedding }
        end

        [:health, :dental].each do |product_kind|
          (health_product_kinds + dental_product_kinds).uniq.each do |package_kind|
            if (product_kind.to_s == 'health' && health_product_kinds.include?(package_kind.to_sym)) || (product_kind.to_s == 'dental' && dental_product_kinds.include?(package_kind.to_sym))
              product_package = benefit_market_catalog.product_packages.where(benefit_kind: kind, product_kind: product_kind, package_kind: package_kind).first_or_create
              product_package.title = package_kind.to_s.titleize,
                product_package.application_period = benefit_market_catalog.application_period,
                product_package.contribution_model = contribution_model,
                product_package.pricing_model = pricing_model

              product_package.products = products_for(product_package, year)
              product_package.save! if product_package.valid? && product_package.products.present?
            end
          end
        end
      end
    end

    desc "remove benefit market catalogs for a given year"
    task :remove_benefit_market_catalogs, [:year] => :environment do |_t, args|
      [:aca_shop, :fehb].each do |kind|
        BenefitMarkets::BenefitMarket.where(:site_urn => EnrollRegistry[:enroll_app].setting(:site_key).item, kind: kind)
                                     .first
                                     .benefit_market_catalogs
                                     .select { |a| a.application_period.first.year.to_s == args[:year].to_s }
          &.first&.delete
      end
    end

    desc 'Create benefit coverage period for a given year'
    task :create_benefit_coverage_period, [:year] => :environment do |t, args|
      year = args[:year].to_i
      coverage_start = DateTime.parse("#{year}-01-01 00:00:00 UTC")
      coverage_end = DateTime.parse("#{year}-12-31 00:00:00 UTC")
      open_enrollment_start_on = Date.yesterday # or TimeKeeper.date_of_record.yesterday
      open_enrollment_end_on = coverage_start

      benefit_coverage_periods = HbxProfile&.current_hbx&.benefit_sponsorship&.benefit_coverage_periods
      service_market = benefit_coverage_periods.first&.service_market
      benefit_coverage_periods.create!(
        start_on: coverage_start,
        end_on: coverage_end,
        open_enrollment_start_on: open_enrollment_start_on,
        open_enrollment_end_on: open_enrollment_end_on,
        service_market: service_market
      )
    end

    desc "remove benefit coverage periods for a given year"
    task :remove_benefit_coverage_periods, [:year] => :environment do |_t, args|
      HbxProfile.current_hbx.benefit_sponsorship.benefit_coverage_periods.select { |bcp| bcp.start_on.year == args[:year].to_i }.delete_all
    end

    desc "create benefit packages for a given year"
    task :create_benefit_packages, [:year] => :environment do |t, args|
      year = args[:year].to_i
      # BenefitPackages - HBX
      hbx = HbxProfile.current_hbx
      abort if hbx.blank?

      bc_period_for_current_year = hbx.benefit_sponsorship.benefit_coverage_periods.select { |bcp| bcp.start_on.year == year }.first
      abort if bc_period_for_current_year.blank?

      slcsp_id = bc_period_for_current_year&.slcsp_id
      slcsp_hios_id = BenefitMarkets::Products::Product.where(id: slcsp_id)&.first&.hios_id ||
        hbx.us_state_abbreviation == 'ME' ? '96667ME0310072-03' : '94506DC0390005-01'
      slcs_products = BenefitMarkets::Products::Product.where(hios_id: slcsp_hios_id)
      slcsp_for_current_year = slcs_products.select { |a| a.active_year == year }.first
      bc_period_for_current_year.slcsp = slcsp_for_current_year.id
      bc_period_for_current_year.slcsp_id = slcsp_for_current_year.id
      ivl_products = BenefitMarkets::Products::Product.aca_individual_market
      ivl_health_plans_for_current_year = ivl_products.where(kind: 'health', hios_id: /-01$/).not_in(metal_level_kind: 'catastrophic').select { |a| a.active_year == year }.entries.collect(&:_id)
      ivl_dental_plans_for_current_year = ivl_products.where(kind: 'dental').select { |a| a.active_year == year }.entries.collect(&:_id)
      ivl_and_cat_health_plans_for_current_year = ivl_products.where(kind: 'health', hios_id: /-01$/).select { |a| a.active_year == year }.entries.collect(&:_id)

      individual_health_benefit_package = BenefitPackage.new(
        title: "individual_health_benefits_#{year}",
        elected_premium_credit_strategy: 'unassisted',
        benefit_ids: ivl_health_plans_for_current_year,
        benefit_eligibility_element_group: BenefitEligibilityElementGroup.new(
          market_places: ['individual'],
          enrollment_periods: ['open_enrollment', 'special_enrollment'],
          family_relationships: BenefitEligibilityElementGroup::INDIVIDUAL_MARKET_RELATIONSHIP_CATEGORY_KINDS,
          benefit_categories: ['health'],
          incarceration_status: ['unincarcerated'],
          age_range: 0..0,
          citizenship_status: ['us_citizen', 'naturalized_citizen', 'alien_lawfully_present', 'lawful_permanent_resident'],
          residency_status: ['state_resident'],
          ethnicity: ['any']
        )
      )

      individual_dental_benefit_package = BenefitPackage.new(
        title: "individual_dental_benefits_#{year}",
        elected_premium_credit_strategy: 'unassisted',
        benefit_ids: ivl_dental_plans_for_current_year,
        benefit_eligibility_element_group: BenefitEligibilityElementGroup.new(
          market_places: ['individual'],
          enrollment_periods: ['open_enrollment', 'special_enrollment'],
          family_relationships: BenefitEligibilityElementGroup::INDIVIDUAL_MARKET_RELATIONSHIP_CATEGORY_KINDS,
          benefit_categories: ['dental'],
          incarceration_status: ['unincarcerated'],
          age_range: 0..0,
          citizenship_status: ['us_citizen', 'naturalized_citizen', 'alien_lawfully_present', 'lawful_permanent_resident'],
          residency_status: ['state_resident'],
          ethnicity: ['any']
        )
      )

      individual_catastrophic_health_benefit_package = BenefitPackage.new(
        title: "catastrophic_health_benefits_#{year}",
        elected_premium_credit_strategy: 'unassisted',
        benefit_ids: ivl_and_cat_health_plans_for_current_year,
        benefit_eligibility_element_group: BenefitEligibilityElementGroup.new(
          market_places: ['individual'],
          enrollment_periods: ['open_enrollment', 'special_enrollment'],
          family_relationships: BenefitEligibilityElementGroup::INDIVIDUAL_MARKET_RELATIONSHIP_CATEGORY_KINDS,
          benefit_categories: ['health'],
          incarceration_status: ['unincarcerated'],
          age_range: 0..30,
          citizenship_status: ['us_citizen', 'naturalized_citizen', 'alien_lawfully_present', 'lawful_permanent_resident'],
          residency_status: ['state_resident'],
          ethnicity: ['any']
        )
      )

      native_american_health_benefit_package = BenefitPackage.new(
        title: "native_american_health_benefits_#{year}",
        elected_premium_credit_strategy: 'unassisted',
        benefit_ids: ivl_health_plans_for_current_year,
        benefit_eligibility_element_group: BenefitEligibilityElementGroup.new(
          market_places: ['individual'],
          enrollment_periods: ['open_enrollment', 'special_enrollment'],
          family_relationships: BenefitEligibilityElementGroup::INDIVIDUAL_MARKET_RELATIONSHIP_CATEGORY_KINDS,
          benefit_categories: ['health'],
          incarceration_status: ['unincarcerated'],
          age_range: 0..0,
          citizenship_status: ['us_citizen', 'naturalized_citizen', 'alien_lawfully_present', 'lawful_permanent_resident'],
          residency_status: ['state_resident'],
          ethnicity: ['indian_tribe_member']
        )
      )

      native_american_dental_benefit_package = BenefitPackage.new(
        title: "native_american_dental_benefits_#{year}",
        elected_premium_credit_strategy: 'unassisted',
        benefit_ids: ivl_dental_plans_for_current_year,
        benefit_eligibility_element_group: BenefitEligibilityElementGroup.new(
          market_places: ['individual'],
          enrollment_periods: ['any'],
          family_relationships: BenefitEligibilityElementGroup::INDIVIDUAL_MARKET_RELATIONSHIP_CATEGORY_KINDS,
          benefit_categories: ['dental'],
          incarceration_status: ['unincarcerated'],
          age_range: 0..0,
          citizenship_status: ['us_citizen', 'naturalized_citizen', 'alien_lawfully_present', 'lawful_permanent_resident'],
          residency_status: ['state_resident'],
          ethnicity: ['indian_tribe_member']
        )
      )

      ivl_health_plans_for_current_year_for_csr_0 = ivl_products.where(
        '$and' => [
          { :kind => 'health' },
          { '$or' => [
            { :metal_level_kind.in => %w(platinum gold bronze), hios_id: /-01$/ },
            { :metal_level_kind => 'silver', hios_id: /-01$/ }
          ]
          }
        ]
      ).select { |a| a.active_year == year }.entries.collect(&:_id)

      ivl_health_plans_for_current_year_for_csr_100 = ivl_products.where(
        '$and' => [{ :kind => 'health' },
                   { '$or' => [{ :metal_level_kind.in => %w[platinum gold bronze], hios_id: /-02$/ },
                               { :metal_level_kind => 'silver', hios_id: /-02$/ }] }]
      ).select { |a| a.active_year == year }.entries.collect(&:_id)

      ivl_health_plans_for_current_year_for_csr_limited = ivl_products.where(
        '$and' => [{ :kind => 'health' },
                   { '$or' => [{ :metal_level_kind.in => %w[platinum gold bronze], hios_id: /-03$/ },
                               { :metal_level_kind => 'silver', hios_id: /-03$/ }] }]
      ).select { |a| a.active_year == year }.entries.collect(&:_id)

      ivl_health_plans_for_current_year_for_csr_94 = ivl_products.where(
        '$and' => [
          { :kind => 'health' },
          { '$or' => [
            { :metal_level_kind.in => %w(platinum gold bronze), :hios_id => /-06$/ },
            { :metal_level_kind => 'silver', :hios_id => /-06$/ }
          ]
          }
        ]
      ).select { |a| a.active_year == year }.entries.collect(&:_id)
      ivl_health_plans_for_current_year_for_csr_87 = ivl_products.where(
        '$and' => [
          { :kind => 'health' },
          { '$or' => [
            { :metal_level_kind.in => %w(platinum gold bronze), :hios_id => /-05$/ },
            { :metal_level_kind => 'silver', :hios_id => /-05$/ }
          ]
          }
        ]
      ).select { |a| a.active_year == year }.entries.collect(&:_id)

      ivl_health_plans_for_current_year_for_csr_73 = ivl_products.where(
        '$and' => [
          { :kind => 'health' },
          { '$or' => [
            { :metal_level_kind.in => %w(platinum gold bronze), :hios_id => /-04$/ },
            { :metal_level_kind => 'silver', :hios_id => /-04$/ }
          ]
          }
        ]
      ).select { |a| a.active_year == year }.entries.collect(&:_id)

      individual_health_benefit_package_for_csr_100 = BenefitPackage.new(
        title: "individual_health_benefits_csr_100_#{year}",
        elected_premium_credit_strategy: 'allocated_lump_sum_credit',
        benefit_ids: ivl_health_plans_for_current_year_for_csr_100,
        benefit_eligibility_element_group: BenefitEligibilityElementGroup.new(
          market_places: ['individual'],
          enrollment_periods: ['open_enrollment', 'special_enrollment'],
          family_relationships: BenefitEligibilityElementGroup::INDIVIDUAL_MARKET_RELATIONSHIP_CATEGORY_KINDS,
          benefit_categories: ['health'],
          incarceration_status: ['unincarcerated'],
          age_range: 0..0,
          cost_sharing: 'csr_100',
          citizenship_status: ['us_citizen', 'naturalized_citizen', 'alien_lawfully_present', 'lawful_permanent_resident'],
          residency_status: ['state_resident'],
          ethnicity: ['any']
        )
      )

      individual_health_benefit_package_for_csr_0 = BenefitPackage.new(
        title: 'individual_health_benefits_csr_0_#{year}',
        elected_premium_credit_strategy: 'allocated_lump_sum_credit',
        benefit_ids: ivl_health_plans_for_current_year_for_csr_0,
        benefit_eligibility_element_group: BenefitEligibilityElementGroup.new(
          market_places: ['individual'],
          enrollment_periods: ['open_enrollment', 'special_enrollment'],
          family_relationships: BenefitEligibilityElementGroup::INDIVIDUAL_MARKET_RELATIONSHIP_CATEGORY_KINDS,
          benefit_categories: ['health'],
          incarceration_status: ['unincarcerated'],
          age_range: 0..0,
          cost_sharing: 'csr_0',
          citizenship_status: ['us_citizen', 'naturalized_citizen', 'alien_lawfully_present', 'lawful_permanent_resident'],
          residency_status: ['state_resident'],
          ethnicity: ['any']
        )
      )

      individual_health_benefit_package_for_csr_limited = BenefitPackage.new(
        title: 'individual_health_benefits_csr_limited_#{year}',
        elected_premium_credit_strategy: 'allocated_lump_sum_credit',
        benefit_ids: ivl_health_plans_for_current_year_for_csr_limited,
        benefit_eligibility_element_group: BenefitEligibilityElementGroup.new(
          market_places: ['individual'],
          enrollment_periods: ['open_enrollment', 'special_enrollment'],
          family_relationships: BenefitEligibilityElementGroup::INDIVIDUAL_MARKET_RELATIONSHIP_CATEGORY_KINDS,
          benefit_categories: ['health'],
          incarceration_status: ['unincarcerated'],
          age_range: 0..0,
          cost_sharing: 'csr_limited',
          citizenship_status: ['us_citizen', 'naturalized_citizen', 'alien_lawfully_present', 'lawful_permanent_resident'],
          residency_status: ['state_resident'],
          ethnicity: ['any']
        )
      )

      individual_health_benefit_package_for_csr_94 = BenefitPackage.new(
        title: "individual_health_benefits_csr_94_#{year}",
        elected_premium_credit_strategy: 'allocated_lump_sum_credit',
        benefit_ids: ivl_health_plans_for_current_year_for_csr_94,
        benefit_eligibility_element_group: BenefitEligibilityElementGroup.new(
          market_places: ['individual'],
          enrollment_periods: ['open_enrollment', 'special_enrollment'],
          family_relationships: BenefitEligibilityElementGroup::INDIVIDUAL_MARKET_RELATIONSHIP_CATEGORY_KINDS,
          benefit_categories: ['health'],
          incarceration_status: ['unincarcerated'],
          age_range: 0..0,
          cost_sharing: 'csr_94',
          citizenship_status: ['us_citizen', 'naturalized_citizen', 'alien_lawfully_present', 'lawful_permanent_resident'],
          residency_status: ['state_resident'],
          ethnicity: ['any']
        )
      )

      individual_health_benefit_package_for_csr_87 = BenefitPackage.new(
        title: "individual_health_benefits_csr_87_#{year}",
        elected_premium_credit_strategy: 'allocated_lump_sum_credit',
        benefit_ids: ivl_health_plans_for_current_year_for_csr_87,
        benefit_eligibility_element_group: BenefitEligibilityElementGroup.new(
          market_places: ['individual'],
          enrollment_periods: ['open_enrollment', 'special_enrollment'],
          family_relationships: BenefitEligibilityElementGroup::INDIVIDUAL_MARKET_RELATIONSHIP_CATEGORY_KINDS,
          benefit_categories: ['health'],
          incarceration_status: ['unincarcerated'],
          age_range: 0..0,
          cost_sharing: 'csr_87',
          citizenship_status: ['us_citizen', 'naturalized_citizen', 'alien_lawfully_present', 'lawful_permanent_resident'],
          residency_status: ['state_resident'],
          ethnicity: ['any']
        )
      )

      individual_health_benefit_package_for_csr_73 = BenefitPackage.new(
        title: "individual_health_benefits_csr_73_#{year}",
        elected_premium_credit_strategy: 'allocated_lump_sum_credit',
        benefit_ids: ivl_health_plans_for_current_year_for_csr_73,
        benefit_eligibility_element_group: BenefitEligibilityElementGroup.new(
          market_places: ['individual'],
          enrollment_periods: ['open_enrollment', 'special_enrollment'],
          family_relationships: BenefitEligibilityElementGroup::INDIVIDUAL_MARKET_RELATIONSHIP_CATEGORY_KINDS,
          benefit_categories: ['health'],
          incarceration_status: ['unincarcerated'],
          age_range: 0..0,
          cost_sharing: 'csr_73',
          citizenship_status: ['us_citizen', 'naturalized_citizen', 'alien_lawfully_present', 'lawful_permanent_resident'],
          residency_status: ['state_resident'],
          ethnicity: ['any']
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

    desc "remove benefit packages for a given year"
    task :remove_benefit_packages, [:year] => :environment do |_t, args|
      BenefitMarkets::Products::BenefitPackage.where(year: args[:year].to_i).delete_all
    end

    desc "create mappings between this and previous year Products and Plans"
    task :create_mappings, [:year] => :environment do |_t, args|
      year = args[:year].to_i
      previous_year = year - 1

      Plan.where(active_year: previous_year).each do |old_plan|
        new_plan = Plan.where(active_year: year, hios_id: old_plan.hios_id).first
        next unless new_plan.present?

        old_plan.update(renewal_plan_id: new_plan.id)
        new_plan.update(sbc_document: old_plan.sbc_document)
      end

      ::BenefitMarkets::Products::Product.by_year(previous_year).each do |old_product|
        new_product = ::BenefitMarkets::Products::Product.where(
          hios_id: old_product.hios_id,
          benefit_market_kind: old_product.benefit_market_kind,
          metal_level_kind: old_product.metal_level_kind
        ).by_year(year).first
        next unless new_product.present?

        old_product.update(renewal_product_id: new_product.id)
        new_product.update(sbc_document: old_product.sbc_document)
      end
    end

    desc "remove mappings between this and previous year Products and Plans"
    task :remove_mappings, [:year] => :environment do |_t, args|
      year = args[:year].to_i
      previous_year = year - 1
      Plan.where(active_year: previous_year).each do |old_plan|
        old_plan.update(renewal_plan_id: nil)
      end
      ::BenefitMarkets::Products::Product.by_year(previous_year).each do |old_product|
        old_product.update(renewal_product_id: nil)
      end
    end

    desc "remove financial assistance applications for a given year"
    task :remove_financial_assistance_applications, [:year] => :environment do |_t, args|
      ::FinancialAssistance::Application.where(application_year: args[:year].to_i).delete_all
    end
  end
end
