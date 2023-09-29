require_relative 'utils'
# Each of the following tasks can be run individually or as part of a larger
# task. For example, you can run `rake dry_run:data:refresh_database[2019]` to
# delete all data for 2019 and then create all data for 2019.

# Each data task is broken into a few parts:
# 1. A method returning the query to retrieve the data (used to retrieve and delete)
# 2. A method to create the data
# 3. A method to delete the data
# 4. A method to retrieve the data

namespace :dry_run do
  namespace :data do
    desc "refresh the database for a given year"
    task :refresh, [:year] => :environment do |_t, args|
      year = args[:year].to_i
      log "Refreshing database for #{year}"
      Rake::Task['dry_run:data:delete_all'].invoke(year)
      Rake::Task['dry_run:data:create_all'].invoke(year)
    end

    desc "all data for a given year"
    task :get_all, [:year] => :environment do |_t, args|
      year = args[:year].to_i
      log "All data for #{year}"
      Rake::Task['dry_run:data:service_areas'].invoke(year)
      Rake::Task['dry_run:data:rating_areas'].invoke(year)
      Rake::Task['dry_run:data:actuarial_factors'].invoke(year)
      # Rake::Task['dry_run:data:plans'].invoke(year) NOT USED SINCE 2019, PRODUCTS ARE USED INSTEAD
      Rake::Task['dry_run:data:products'].invoke(year)
      Rake::Task['dry_run:data:benefit_coverage_period'].invoke(year)
      Rake::Task['dry_run:data:benefit_packages'].invoke(year)
      Rake::Task['dry_run:data:benefit_market_catalogs'].invoke(year)
      Rake::Task['dry_run:data:financial_assistance_applications'].invoke(year)
    end

    desc "create all data for a given year"
    task :create_all, [:year] => :environment do |_t, args|
      year = args[:year].to_i
      log "Creating all data for #{year}"
      Rake::Task['dry_run:data:create_service_areas'].invoke(year)
      Rake::Task['dry_run:data:create_rating_areas'].invoke(year)
      Rake::Task['dry_run:data:create_actuarial_factors'].invoke(year)
      Rake::Task['dry_run:data:create_plans'].invoke(year)
      Rake::Task['dry_run:data:create_products'].invoke(year)
      Rake::Task['dry_run:data:create_benefit_coverage_period'].invoke(year)
      Rake::Task['dry_run:data:create_benefit_packages'].invoke(year)
      Rake::Task['dry_run:data:create_benefit_market_catalogs'].invoke(year)
      Rake::Task['dry_run:data:create_mappings'].invoke(year)
    end

    desc "delete all data for a given year"
    task :delete_all, [:year] => :environment do |_t, args|
      year = args[:year].to_i
      log "Removing all data for #{year}"
      Rake::Task['dry_run:data:delete_service_areas'].invoke(year)
      Rake::Task['dry_run:data:delete_rating_areas'].invoke(year)
      Rake::Task['dry_run:data:delete_actuarial_factors'].invoke(year)
      Rake::Task['dry_run:data:delete_plans'].invoke(year)
      Rake::Task['dry_run:data:delete_products'].invoke(year)
      Rake::Task['dry_run:data:delete_benefit_coverage_period'].invoke(year)
      Rake::Task['dry_run:data:delete_benefit_packages'].invoke(year)
      Rake::Task['dry_run:data:delete_benefit_market_catalogs'].invoke(year)
      Rake::Task['dry_run:data:delete_mappings'].invoke(year)
      Rake::Task['dry_run:data:delete_financial_assistance_applications'].invoke(year)
      Rake::Task['dry_run:data:delete_enrollments'].invoke(year)
    end

    def service_areas_by_year(year)
      ::BenefitMarkets::Locations::ServiceArea.where(active_year: year)
    end

    desc "service areas for a given year"
    task :service_areas, [:year] => :environment do |_t, args|
      get_all(service_areas_by_year(args[:year]))
    end

    desc "delete service areas for a given year"
    task :delete_service_areas, [:year] => :environment do |_t, args|
      delete_all(service_areas_by_year(args[:year]))
    end

    desc "create service areas for a given year"
    task :create_service_areas, [:year] => :environment do |_t, args|
      log "Creating service areas for #{args[:year]}"
      begin
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
      rescue StandardError => e
        log "Error creating service areas for #{args[:year]}", e.message, e.backtrace
        exit 1
      end
    end

    def rating_areas_by_year(year)
      ::BenefitMarkets::Locations::RatingArea.where(active_year: year)
    end

    desc "rating areas for a given year"
    task :rating_areas, [:year] => :environment do |_t, args|
      get_all(rating_areas_by_year(args[:year]))
    end

    desc "delete rating areas for a given year"
    task :delete_rating_areas, [:year] => :environment do |_t, args|
      delete_all(rating_areas_by_year(args[:year]))
    end

    desc "create rating areas for a given year"
    task :create_rating_areas, [:year] => :environment do |_t, args|
      log "Creating rating areas for #{args[:year]}"
      begin
        ::BenefitMarkets::Locations::RatingArea.find_or_create_by!({
                                                                     active_year: args[:year].to_i,
                                                                     exchange_provided_code: EnrollRegistry[:exchange_provided_code].item,
                                                                     county_zip_ids: [], #@todo: add county_zip_ids
                                                                     covered_states: [EnrollRegistry[:enroll_app].setting(:state_abbreviation)&.item]
                                                                   })
      rescue StandardError => e
        log "Error creating rating areas for #{args[:year]}", e.message, e.backtrace
        exit 1
      end
    end

    def plans_by_year(year, **options)
      ::Plan.where(active_year: year, **options)
    end

    desc "plans for a given year"
    task :plans, [:year] => :environment do |_t, args|
      get_all(plans_by_year(args[:year]))
    end

    desc "delete plans for a given year"
    task :delete_plans, [:year] => :environment do |_t, args|
      delete_all(plans_by_year(args[:year]))
    end

    desc "create plans for a given year"
    task :create_plans, [:year] => :environment do |_t, args|
      year = args[:year].to_i
      log "Creating plans for #{year}"
      begin
        plans_by_year(year.pred).each do |plan|
          new_service_area = ::BenefitMarkets::Locations::ServiceArea.where(
            active_year: year,
            issuer_profile_id: plan.carrier_profile_id
          ).first

          next if plans_by_year(year, hios_id: plan.hios_id, market: plan.market).present?

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
      rescue StandardError => e
        log "Error creating plans for #{args[:year]}", e.message, e.backtrace
        exit 1
      end
    end

    def products_by_year(year, **options)
      products = ::BenefitMarkets::Products::Product.by_year(year)
      products = products.where(**options) if options.present?
      products
    end

    desc "products for a given year"
    task :products, [:year] => :environment do |_t, args|
      get_all(products_by_year(args[:year]))
    end

    desc "delete products for a given year"
    task :delete_products, [:year] => :environment do |_t, args|
      delete_all(products_by_year(args[:year]))
    end

    desc "create products for a given year"
    task :create_products, [:year] => :environment do |_t, args|
      year = args[:year].to_i
      log "Creating products for #{year}"
      begin
        rating_area = ::BenefitMarkets::Locations::RatingArea.where(active_year: year).first
        raise "No rating area found for #{year}. Try running rake dry_run:data:create_rating_areas[#{year}]" if rating_area.nil?

        products_by_year(year.pred).each do |product|
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
      rescue StandardError => e
        log "Error creating products for #{args[:year]}", e.message, e.backtrace
        exit 1
      end
    end

    def actuarial_factors_by_year(year)
      { participation: ::BenefitMarkets::Products::ActuarialFactors::ParticipationRateActuarialFactor.where(active_year: year),
        group: ::BenefitMarkets::Products::ActuarialFactors::GroupSizeActuarialFactor.where(active_year: year) }
    end

    desc "actuarial factors for a given year"
    task :actuarial_factors, [:year] => :environment do |_t, args|
      actuarial_factors_by_year(args[:year]).each do |_k, v|
        get_all(v)
      end
    end

    desc "delete actuarial factors for a given year"
    task :delete_actuarial_factors, [:year] => :environment do |_t, args|
      actuarial_factors_by_year(args[:year]).each do |_k, v|
        delete_all(v)
      end
    end

    desc "create actuarial factors for a given year"
    task :create_actuarial_factors, [:year] => :environment do |_t, args|
      year = args[:year].to_i
      log "Creating actuarial factors for #{year}"
      begin
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
      rescue StandardError => e
        log "Error creating actuarial factors for #{args[:year]}", e.message, e.backtrace
        exit 1
      end
    end

    def benefit_market_catalogs_by_year(year)
      site_urn = EnrollRegistry[:enroll_app].setting(:site_key).item

      result = [:aca_shop, :fehb].flat_map do |kind|
        BenefitMarkets::BenefitMarket
          .where(site_urn: site_urn, kind: kind)
          .first
          &.benefit_market_catalogs
          &.where(application_period: { '$elemMatch': { start_on: { '$gte': Date.new(year.to_i, 1, 1), '$lt': Date.new(year.to_i + 1, 1, 1) } } })
      end

      # Return a default BenefitMarkets::BenefitMarketCatalog.none to ensure consistency with returning a Mongoid::Criteria object
      result.any? ? result : [BenefitMarkets::BenefitMarketCatalog.none]
    end

    desc "benefit market catalogs for a given year"
    task :benefit_market_catalogs, [:year] => :environment do |_t, args|
      benefit_market_catalogs_by_year(args[:year]).each { |bmc| get_all(bmc) }
    end

    desc "delete benefit market catalogs for a given year"
    task :delete_benefit_market_catalogs, [:year] => :environment do |_t, args|
      benefit_market_catalogs_by_year(args[:year]).each { |bmc| delete_all(bmc) }
    end

    # @todo: this task comes from load_dc_benefit_market_catalog.rake it may be specific to DC. What is benefit market catalog?
    desc "create benefit market catalogs for a given year"
    task :create_benefit_market_catalogs, [:year] => :environment do |_t, args|
      year = args[:year].to_i
      log "Creating benefit market catalogs for #{year}"
      begin
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
      rescue StandardError => e
        log "Error creating benefit market catalogs for #{year}", e.message, e.backtrace
        exit 1
      end
    end

    def benefit_coverage_period_by_year(year)
      year = year.to_i
      start_date = Date.new(year, 1, 1)
      end_date = Date.new(year + 1, 1, 1)
      HbxProfile.current_hbx.benefit_sponsorship.benefit_coverage_periods.where(start_on: { '$gte': start_date, '$lt': end_date })
    end

    desc "benefit coverage period for a given year"
    task :benefit_coverage_period, [:year] => :environment do |_t, args|
      get_all(benefit_coverage_period_by_year(args[:year]))
    end

    desc "delete benefit coverage periods for a given year"
    task :delete_benefit_coverage_period, [:year] => :environment do |_t, args|
      delete_all(benefit_coverage_period_by_year(args[:year]))
    end

    desc 'create benefit coverage period for a given year'
    task :create_benefit_coverage_period, [:year] => :environment do |t, args|
      year = args[:year].to_i
      log "Creating benefit coverage period for #{year}"
      HbxProfile&.current_hbx&.benefit_sponsorship&.benefit_coverage_periods.create!(
        title: "Individual Market Benefits #{year}",
        service_market: 'individual',
        start_on: Date.new(year, 1, 1),
        end_on: Date.new(year, 12, 31),
        open_enrollment_start_on: TimeKeeper.date_of_record.yesterday,
        open_enrollment_end_on: Date.new(year, 1, 31)
      )
    end

    def benefit_packages_by_year(year)
      hbx = HbxProfile.current_hbx

      benefit_coverage_period = hbx&.benefit_sponsorship&.benefit_coverage_periods
                                  &.where("start_on" => { "$gte": Date.new(year.to_i, 1, 1), "$lt": Date.new(year.to_i + 1, 1, 1) })
                                  &.first

      # Return a default ::BenefitSponsors::BenefitPackages::BenefitPackage.none to ensure consistency with returning a Mongoid::Criteria object
      benefit_coverage_period&.benefit_packages || ::BenefitSponsors::BenefitPackages::BenefitPackage.none
    end

    desc "benefit packages for a given year"
    task :benefit_packages, [:year] => :environment do |_t, args|
      get_all(benefit_packages_by_year(args[:year]))
    end

    desc "delete benefit packages for a given year"
    task :delete_benefit_packages, [:year] => :environment do |_t, args|
      delete_all(benefit_packages_by_year(args[:year]))
    end

    desc "create benefit packages for a given year"
    task :create_benefit_packages, [:year] => :environment do |t, args|
      current_year = args[:year].to_i
      previous_year = current_year.pred
      log "Creating benefit packages for #{current_year}"
      begin
        # BenefitPackages - HBX
        hbx = HbxProfile.current_hbx
        raise "HBX profile not found" if hbx.blank?

        #
        # check if benefit package is present
        #
        bc_period_for_current_year = hbx.benefit_sponsorship.benefit_coverage_periods.select { |bcp| bcp.start_on.year == current_year }.first

        #
        # Second lowest cost silver plan
        #
        slcsp_id = bc_period_for_current_year&.slcsp_id
        slcsp_hios_id = BenefitMarkets::Products::Product.where(id: slcsp_id)&.first&.hios_id ||
          hbx.us_state_abbreviation == "ME" ? "96667ME0310072-03" : "94506DC0390005-01"
        slcs_products = BenefitMarkets::Products::Product.where(hios_id: slcsp_hios_id)
        slcsp_for_current_year = slcs_products.select { |a| a.active_year == current_year }.first

        raise "No slcsp_for_current_year present" if slcsp_for_current_year.blank?

        if bc_period_for_current_year.present?
          bc_period_for_current_year.slcsp = slcsp_for_current_year.id
          bc_period_for_current_year.slcsp_id = slcsp_for_current_year.id
        else
          # create benefit package and benefit_coverage_period
          bc_period_for_previous_year = hbx.benefit_sponsorship.benefit_coverage_periods.select { |bcp| bcp.start_on.year == previous_year }&.first || hbx.benefit_sponsorship.benefit_coverage_periods.first
          bc_period_for_current_year = bc_period_for_previous_year.clone
          bc_period_for_current_year.title = "Individual Market Benefits #{current_year}"
          bc_period_for_current_year.start_on = Date.new(current_year, 1, 1)
          bc_period_for_current_year.end_on = Date.new(current_year, 12, 31)

          # if we need to change these dates after running this rake task in test or prod environments,
          # we should write a separate script.
          bc_period_for_current_year.open_enrollment_start_on = Date.new(previous_year, 11, 1)
          bc_period_for_current_year.open_enrollment_end_on = Date.new(current_year, 1, 31)

          bc_period_for_current_year.slcsp = slcsp_for_current_year.id
          bc_period_for_current_year.slcsp_id = slcsp_for_current_year.id

          bs = hbx.benefit_sponsorship
          bs.benefit_coverage_periods << bc_period_for_current_year
          raise bs.errors.full_messages.join(', ') unless bs.save
        end

        ivl_products = BenefitMarkets::Products::Product.aca_individual_market
        raise "No ivl product present" if ivl_products.blank?

        ivl_health_plans_for_current_year = ivl_products.where(kind: "health", hios_id: /-01$/).not_in(metal_level_kind: "catastrophic").select { |a| a.active_year == current_year }.entries.collect(&:_id)
        ivl_dental_plans_for_current_year = ivl_products.where(kind: "dental").select { |a| a.active_year == current_year }.entries.collect(&:_id)
        ivl_and_cat_health_plans_for_current_year = ivl_products.where(kind: "health", hios_id: /-01$/).select { |a| a.active_year == current_year }.entries.collect(&:_id)

        individual_health_benefit_package = BenefitPackage.new(
          title: "individual_health_benefits_#{current_year}",
          elected_premium_credit_strategy: "unassisted",
          benefit_ids: ivl_health_plans_for_current_year,
          benefit_eligibility_element_group: BenefitEligibilityElementGroup.new(
            market_places: ["individual"],
            enrollment_periods: ["open_enrollment", "special_enrollment"],
            family_relationships: BenefitEligibilityElementGroup::INDIVIDUAL_MARKET_RELATIONSHIP_CATEGORY_KINDS,
            benefit_categories: ["health"],
            incarceration_status: ["unincarcerated"],
            age_range: 0..0,
            citizenship_status: ["us_citizen", "naturalized_citizen", "alien_lawfully_present", "lawful_permanent_resident"],
            residency_status: ["state_resident"],
            ethnicity: ["any"]
          )
        )

        individual_dental_benefit_package = BenefitPackage.new(
          title: "individual_dental_benefits_#{current_year}",
          elected_premium_credit_strategy: "unassisted",
          benefit_ids: ivl_dental_plans_for_current_year,
          benefit_eligibility_element_group: BenefitEligibilityElementGroup.new(
            market_places: ["individual"],
            enrollment_periods: ["open_enrollment", "special_enrollment"],
            family_relationships: BenefitEligibilityElementGroup::INDIVIDUAL_MARKET_RELATIONSHIP_CATEGORY_KINDS,
            benefit_categories: ["dental"],
            incarceration_status: ["unincarcerated"],
            age_range: 0..0,
            citizenship_status: ["us_citizen", "naturalized_citizen", "alien_lawfully_present", "lawful_permanent_resident"],
            residency_status: ["state_resident"],
            ethnicity: ["any"]
          )
        )

        individual_catastrophic_health_benefit_package = BenefitPackage.new(
          title: "catastrophic_health_benefits_#{current_year}",
          elected_premium_credit_strategy: "unassisted",
          benefit_ids: ivl_and_cat_health_plans_for_current_year,
          benefit_eligibility_element_group: BenefitEligibilityElementGroup.new(
            market_places: ["individual"],
            enrollment_periods: ["open_enrollment", "special_enrollment"],
            family_relationships: BenefitEligibilityElementGroup::INDIVIDUAL_MARKET_RELATIONSHIP_CATEGORY_KINDS,
            benefit_categories: ["health"],
            incarceration_status: ["unincarcerated"],
            age_range: 0..30,
            citizenship_status: ["us_citizen", "naturalized_citizen", "alien_lawfully_present", "lawful_permanent_resident"],
            residency_status: ["state_resident"],
            ethnicity: ["any"]
          )
        )

        native_american_health_benefit_package = BenefitPackage.new(
          title: "native_american_health_benefits_#{current_year}",
          elected_premium_credit_strategy: "unassisted",
          benefit_ids: ivl_health_plans_for_current_year,
          benefit_eligibility_element_group: BenefitEligibilityElementGroup.new(
            market_places: ["individual"],
            enrollment_periods: ["open_enrollment", "special_enrollment"],
            family_relationships: BenefitEligibilityElementGroup::INDIVIDUAL_MARKET_RELATIONSHIP_CATEGORY_KINDS,
            benefit_categories: ["health"],
            incarceration_status: ["unincarcerated"],
            age_range: 0..0,
            citizenship_status: ["us_citizen", "naturalized_citizen", "alien_lawfully_present", "lawful_permanent_resident"],
            residency_status: ["state_resident"],
            ethnicity: ["indian_tribe_member"]
          )
        )

        native_american_dental_benefit_package = BenefitPackage.new(
          title: "native_american_dental_benefits_#{current_year}",
          elected_premium_credit_strategy: "unassisted",
          benefit_ids: ivl_dental_plans_for_current_year,
          benefit_eligibility_element_group: BenefitEligibilityElementGroup.new(
            market_places: ["individual"],
            enrollment_periods: ["any"],
            family_relationships: BenefitEligibilityElementGroup::INDIVIDUAL_MARKET_RELATIONSHIP_CATEGORY_KINDS,
            benefit_categories: ["dental"],
            incarceration_status: ["unincarcerated"],
            age_range: 0..0,
            citizenship_status: ["us_citizen", "naturalized_citizen", "alien_lawfully_present", "lawful_permanent_resident"],
            residency_status: ["state_resident"],
            ethnicity: ["indian_tribe_member"]
          )
        )

        ivl_health_plans_for_current_year_for_csr_0 = ivl_products.where(
          "$and" => [
            { :kind => "health" },
            { "$or" => [
              { :metal_level_kind.in => %w(platinum gold bronze), hios_id: /-01$/ },
              { :metal_level_kind => "silver", hios_id: /-01$/ }
            ]
            }
          ]
        ).select { |a| a.active_year == current_year }.entries.collect(&:_id)

        ivl_health_plans_for_current_year_for_csr_100 = ivl_products.where(
          "$and" => [{ :kind => 'health' },
                     { "$or" => [{ :metal_level_kind.in => %w[platinum gold bronze], hios_id: /-02$/ },
                                 { :metal_level_kind => 'silver', hios_id: /-02$/ }] }]
        ).select { |a| a.active_year == current_year }.entries.collect(&:_id)

        ivl_health_plans_for_current_year_for_csr_limited = ivl_products.where(
          "$and" => [{ :kind => 'health' },
                     { "$or" => [{ :metal_level_kind.in => %w[platinum gold bronze], hios_id: /-03$/ },
                                 { :metal_level_kind => 'silver', hios_id: /-03$/ }] }]
        ).select { |a| a.active_year == current_year }.entries.collect(&:_id)

        ivl_health_plans_for_current_year_for_csr_94 = ivl_products.where(
          "$and" => [
            { :kind => "health" },
            { "$or" => [
              { :metal_level_kind.in => %w(platinum gold bronze), :hios_id => /-06$/ },
              { :metal_level_kind => "silver", :hios_id => /-06$/ }
            ]
            }
          ]
        ).select { |a| a.active_year == current_year }.entries.collect(&:_id)
        ivl_health_plans_for_current_year_for_csr_87 = ivl_products.where(
          "$and" => [
            { :kind => "health" },
            { "$or" => [
              { :metal_level_kind.in => %w(platinum gold bronze), :hios_id => /-05$/ },
              { :metal_level_kind => "silver", :hios_id => /-05$/ }
            ]
            }
          ]
        ).select { |a| a.active_year == current_year }.entries.collect(&:_id)

        ivl_health_plans_for_current_year_for_csr_73 = ivl_products.where(
          "$and" => [
            { :kind => "health" },
            { "$or" => [
              { :metal_level_kind.in => %w(platinum gold bronze), :hios_id => /-04$/ },
              { :metal_level_kind => "silver", :hios_id => /-04$/ }
            ]
            }
          ]
        ).select { |a| a.active_year == current_year }.entries.collect(&:_id)

        individual_health_benefit_package_for_csr_100 = BenefitPackage.new(
          title: "individual_health_benefits_csr_100_#{current_year}",
          elected_premium_credit_strategy: "allocated_lump_sum_credit",
          benefit_ids: ivl_health_plans_for_current_year_for_csr_100,
          benefit_eligibility_element_group: BenefitEligibilityElementGroup.new(
            market_places: ["individual"],
            enrollment_periods: ["open_enrollment", "special_enrollment"],
            family_relationships: BenefitEligibilityElementGroup::INDIVIDUAL_MARKET_RELATIONSHIP_CATEGORY_KINDS,
            benefit_categories: ["health"],
            incarceration_status: ["unincarcerated"],
            age_range: 0..0,
            cost_sharing: "csr_100",
            citizenship_status: ["us_citizen", "naturalized_citizen", "alien_lawfully_present", "lawful_permanent_resident"],
            residency_status: ["state_resident"],
            ethnicity: ["any"]
          )
        )

        individual_health_benefit_package_for_csr_0 = BenefitPackage.new(
          title: "individual_health_benefits_csr_0_#{current_year}",
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
          title: "individual_health_benefits_csr_limited_#{current_year}",
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
          title: "individual_health_benefits_csr_94_#{current_year}",
          elected_premium_credit_strategy: "allocated_lump_sum_credit",
          benefit_ids: ivl_health_plans_for_current_year_for_csr_94,
          benefit_eligibility_element_group: BenefitEligibilityElementGroup.new(
            market_places: ["individual"],
            enrollment_periods: ["open_enrollment", "special_enrollment"],
            family_relationships: BenefitEligibilityElementGroup::INDIVIDUAL_MARKET_RELATIONSHIP_CATEGORY_KINDS,
            benefit_categories: ["health"],
            incarceration_status: ["unincarcerated"],
            age_range: 0..0,
            cost_sharing: "csr_94",
            citizenship_status: ["us_citizen", "naturalized_citizen", "alien_lawfully_present", "lawful_permanent_resident"],
            residency_status: ["state_resident"],
            ethnicity: ["any"]
          )
        )

        individual_health_benefit_package_for_csr_87 = BenefitPackage.new(
          title: "individual_health_benefits_csr_87_#{current_year}",
          elected_premium_credit_strategy: "allocated_lump_sum_credit",
          benefit_ids: ivl_health_plans_for_current_year_for_csr_87,
          benefit_eligibility_element_group: BenefitEligibilityElementGroup.new(
            market_places: ["individual"],
            enrollment_periods: ["open_enrollment", "special_enrollment"],
            family_relationships: BenefitEligibilityElementGroup::INDIVIDUAL_MARKET_RELATIONSHIP_CATEGORY_KINDS,
            benefit_categories: ["health"],
            incarceration_status: ["unincarcerated"],
            age_range: 0..0,
            cost_sharing: "csr_87",
            citizenship_status: ["us_citizen", "naturalized_citizen", "alien_lawfully_present", "lawful_permanent_resident"],
            residency_status: ["state_resident"],
            ethnicity: ["any"]
          )
        )

        individual_health_benefit_package_for_csr_73 = BenefitPackage.new(
          title: "individual_health_benefits_csr_73_#{current_year}",
          elected_premium_credit_strategy: "allocated_lump_sum_credit",
          benefit_ids: ivl_health_plans_for_current_year_for_csr_73,
          benefit_eligibility_element_group: BenefitEligibilityElementGroup.new(
            market_places: ["individual"],
            enrollment_periods: ["open_enrollment", "special_enrollment"],
            family_relationships: BenefitEligibilityElementGroup::INDIVIDUAL_MARKET_RELATIONSHIP_CATEGORY_KINDS,
            benefit_categories: ["health"],
            incarceration_status: ["unincarcerated"],
            age_range: 0..0,
            cost_sharing: "csr_73",
            citizenship_status: ["us_citizen", "naturalized_citizen", "alien_lawfully_present", "lawful_permanent_resident"],
            residency_status: ["state_resident"],
            ethnicity: ["any"]
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
        log "Created benefit packages for #{current_year}"
      rescue StandardError => e
        log "Error creating benefit packages for #{current_year}", e.message, e.backtrace
        exit 1
      end
    end

    desc "delete mappings between this and previous year Products and Plans"
    task :delete_mappings, [:year] => :environment do |_t, args|
      year = args[:year].to_i
      previous_year = year - 1
      Plan.where(active_year: previous_year).each do |old_plan|
        old_plan.update(renewal_plan_id: nil)
      end
      ::BenefitMarkets::Products::Product.by_year(previous_year).each do |old_product|
        old_product.update(renewal_product_id: nil)
      end
    end

    desc "create mappings between this and previous year Products and Plans"
    task :create_mappings, [:year] => :environment do |_t, args|
      year = args[:year].to_i
      previous_year = year.pred
      log "Creating mappings between #{previous_year} and #{year} Products and Plans"
      begin
        plans_by_year(previous_year).each do |old_plan|
          new_plan = Plan.where(active_year: year, hios_id: old_plan.hios_id).first
          next unless new_plan.present?

          old_plan.update(renewal_plan_id: new_plan.id)
          new_plan.update(sbc_document: old_plan.sbc_document)
        end

        products_by_year(previous_year).each do |old_product|
          new_product = products_by_year(year,
                                         hios_id: old_product.hios_id,
                                         benefit_market_kind: old_product.benefit_market_kind,
                                         metal_level_kind: old_product.metal_level_kind).first
          next unless new_product.present?

          # @todo THIS is broken
          old_product.update(renewal_product_id: new_product.id)
          new_product.update(sbc_document: old_product.sbc_document)
        end
      rescue StandardError => e
        log "Error creating mappings between #{previous_year} and #{year} Products and Plans", e.message, e.backtrace
        exit 1
      end
    end

    def financial_assistance_applications_by_year(year)
      ::FinancialAssistance::Application.by_year(year)
    end

    desc "financial assistance applications for a given year"
    task :financial_assistance_applications, [:year] => :environment do |_t, args|
      get_all(financial_assistance_applications_by_year(args[:year]))
    end

    desc "delete financial assistance applications for a given year"
    task :delete_financial_assistance_applications, [:year] => :environment do |_t, args|
      delete_all(financial_assistance_applications_by_year(args[:year]))
    end

    desc "enrollments for a given year"
    task :enrollments, [:year] => :environment do |_t, args|
      get_all(::HbxEnrollment.by_year(args[:year]))
    end

    desc "delete enrollments for a given year"
    task :delete_enrollments, [:year] => :environment do |_t, args|
      delete_all(::HbxEnrollment.by_year(args[:year]))
    end

  end
end
