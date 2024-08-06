# frozen_string_literal: true

# these rake tasks should only be run for mocking data, these should not be run for anything else.

namespace :new_model do


  desc "new model mock data rake tasks"
  task :reset_data, [:year] => :environment do |_t, args|

    mock_year = args[:year].present? ? args[:year].to_i : 2022
    puts "Reset for #{mock_year} started" unless Rails.env.test?

    puts "Reseting service areas for #{mock_year}" unless Rails.env.test?
    ::BenefitMarkets::Locations::ServiceArea.where(active_year: mock_year).delete_all
    puts "Reseting rating areas for #{mock_year}" unless Rails.env.test?
    ::BenefitMarkets::Locations::RatingArea.where(active_year: mock_year).delete_all
    puts "Reseting ParticipationRateActuarialFactor for #{mock_year}" unless Rails.env.test?
    ::BenefitMarkets::Products::ActuarialFactors::ParticipationRateActuarialFactor.where(active_year: mock_year).delete_all
    puts "Reseting GroupSizeActuarialFactor for #{mock_year}" unless Rails.env.test?
    ::BenefitMarkets::Products::ActuarialFactors::GroupSizeActuarialFactor.where(active_year: mock_year).delete_all

    puts "Reseting Products for #{mock_year}" unless Rails.env.test?
    ::BenefitMarkets::Products::Product.by_year(mock_year).delete_all

    puts "Reseting IVL Benefit coverage Period for #{mock_year}" unless Rails.env.test?
    HbxProfile.current_hbx.benefit_sponsorship.benefit_coverage_periods.select { |bcp| bcp.start_on.year == mock_year }&.first&.delete

    [:aca_shop, :fehb].each do |kind|
      puts "Reseting #{kind} benefit_market_catalog for Period #{mock_year}" unless Rails.env.test?
      BenefitMarkets::BenefitMarket.where(:site_urn => EnrollRegistry[:enroll_app].setting(:site_key).item, kind: kind)
                                   .first
                                   .benefit_market_catalogs
                                   .select { |a| a.application_period.first.year.to_s == mock_year.to_s }
                                   &.first&.delete
    end

    puts "Reset for #{mock_year} completed" unless Rails.env.test?
  end

  desc "new model mock data rake tasks"
  task :mock_data, [:year] => :environment do |_t, args|

    mock_year = args[:year].present? ? args[:year].to_i : 2022

    puts "Mock Data for #{mock_year} started" unless Rails.env.test?
    Rake::Task['new_model:rating_areas'].invoke(mock_year)
    Rake::Task['new_model:service_areas'].invoke(mock_year)

    puts "loading #{mock_year} plans" unless Rails.env.test?
    Rake::Task['new_model:plans_and_rates'].invoke(mock_year)

    Rake::Task['new_model:rating_factors'].invoke(mock_year)
    Rake::Task['new_model:plan_cross_walk'].invoke(mock_year)

    # Commenting these out since we need only in DC context

    # puts "loading #{mock_year} benefit market catalog" unless Rails.env.test?
    # Rake::Task['load:dc_benefit_market_catalog'].invoke(mock_year)

    # puts "loading #{mock_year} ivl benefit pacakges" unless Rails.env.test?
    # Rake::Task["import:create_ivl_packages_DC"].invoke(mock_year)

    # Picking previous year's slcsp_id to create slcsp_id since this is mock data.
    slcsp_id = HbxProfile&.current_hbx&.benefit_sponsorship&.benefit_coverage_periods&.by_year(mock_year - 1)&.first&.slcsp_id
    hios_id = BenefitMarkets::Products::Product.find(slcsp_id).hios_id

    puts "loading #{mock_year} ivl benefit pacakges" unless Rails.env.test?
    Rake::Task["import:create_ivl_packages_ME"].invoke(mock_year, hios_id)

    Rake::Task['new_model:map_sbc'].invoke(mock_year)
    puts "Mock Data for #{mock_year} completed" unless Rails.env.test?
  end

  desc "rating areas"
  task :rating_areas, [:year] => :environment do |_t, args|
    [args[:year]].each do |year|
      puts "Creating Rating areas for new model #{year}" unless Rails.env.test?
      ::BenefitMarkets::Locations::RatingArea.find_or_create_by!({
                                                                   active_year: args[:year],
                                                                   exchange_provided_code: EnrollRegistry[:exchange_provided_code].item,
                                                                   county_zip_ids: [],
                                                                   covered_states: [EnrollRegistry[:enroll_app].setting(:state_abbreviation)&.item]
                                                                 })
    end
  end

  desc "service areas"
  task :service_areas, [:year] => :environment do |_t, args|
    [args[:year]].each do |year|
      puts "Creating Service areas for new model #{year}" unless Rails.env.test?
      ::BenefitSponsors::Organizations::Organization.issuer_profiles.each do |issuer_organization|
        issuer_profile = issuer_organization.issuer_profile
        issuer_profile.issuer_hios_ids.each do |issuer_hios_id|
          ::BenefitMarkets::Locations::ServiceArea.find_or_create_by!({
                                                                        active_year: args[:year],
                                                                        issuer_provided_code: EnrollRegistry[:issuer_provided_code].item,
                                                                        covered_states: [EnrollRegistry[:enroll_app].setting(:state_abbreviation)&.item],
                                                                        county_zip_ids: [],
                                                                        issuer_profile_id: issuer_profile.id,
                                                                        issuer_hios_id: issuer_hios_id,
                                                                        issuer_provided_title: issuer_profile.legal_name
                                                                      })
        end
      end
    end
  end

  desc "mock plans_and_rates"
  task :plans_and_rates, [:year] => :environment do |_t, args|
    mock_year = args[:year]
    previous_year = mock_year - 1

    rating_area = ::BenefitMarkets::Locations::RatingArea.where(active_year: mock_year).first

    ::BenefitMarkets::Products::Product.by_year(previous_year).each do |product|
      new_service_area = ::BenefitMarkets::Locations::ServiceArea.where(
        active_year: mock_year,
        issuer_profile_id: product.issuer_profile_id
      ).first

      next if ::BenefitMarkets::Products::Product.by_year(mock_year).where(hios_id: product.hios_id, benefit_market_kind: product.benefit_market_kind).present?

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
        active_year: mock_year,
        issuer_profile_id: plan.carrier_profile_id
      ).first

      next if ::Plan.where(active_year: mock_year, hios_id: plan.hios_id, market: plan.market).present?

      new_plan = plan.dup
      new_plan.active_year = mock_year
      new_plan.service_area_id =
        if new_service_area.nil?
          site_key = EnrollRegistry[:enroll_app].setting(:site_key).item
          "#{site_key.upcase}S002"
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

  desc "rating factors"
  task :rating_factors, [:year] => :environment do |_t, args|
    [args[:year]].each do |year|
      puts "creating rating factors for #{year}" unless Rails.env.test?
      ::BenefitSponsors::Organizations::Organization.issuer_profiles.each do |issuer_organization|
        issuer_profile = issuer_organization.issuer_profile
          # participation rate factor
        ::BenefitMarkets::Products::ActuarialFactors::ParticipationRateActuarialFactor.find_or_create_by!(
          active_year: year,
          default_factor_value: 1.0,
          max_integer_factor_key: 100,
          issuer_profile_id: issuer_profile.id,
          actuarial_factor_entries: []
        )
        # group size factor
        ::BenefitMarkets::Products::ActuarialFactors::GroupSizeActuarialFactor.find_or_create_by!(
          active_year: year,
          default_factor_value: 1.0,
          max_integer_factor_key: 1,
          issuer_profile_id: issuer_profile.id,
          actuarial_factor_entries: []
        )
      end
    end
  end

  # plan cross walk
  desc "Import plan crosswalk"
  task :plan_cross_walk, [:year] => :environment do |_t, args|
    year = args[:year]
    previous_year = year - 1
    puts "mapping plans from #{previous_year} -> #{year}" unless Rails.env.test?
    # old plans
    Plan.where(active_year: previous_year).each do |old_plan|
      new_plan = Plan.where(active_year: year, hios_id: old_plan.hios_id).first
      next unless new_plan.present?
      old_plan.renewal_plan_id = new_plan.id
      old_plan.save
      puts "Old #{old_plan.active_year} plan hios_id #{old_plan.hios_id} renewed with New #{new_plan.hios_id} plan hios_id: #{new_plan.hios_id}" unless Rails.env.test?
    end
    # end old plans
    ::BenefitMarkets::Products::Product.by_year(previous_year).each do |old_product|
      new_product = ::BenefitMarkets::Products::Product.where(
        hios_id: old_product.hios_id,
        benefit_market_kind: old_product.benefit_market_kind,
        metal_level_kind: old_product.metal_level_kind
      ).by_year(year).first
      if new_product.present?
        old_product.renewal_product_id = new_product.id
        old_product.save
        puts "Old #{old_product.active_year} product hios_id #{old_product.hios_id} renewed with New #{new_product.active_year} product hios_id: #{new_product.hios_id}" unless Rails.env.test?
      else
        puts "product not present: #{old_product.hios_id}"
      end
    end
    # new plans
    # end new plans
  end

  # map sbc documents
  desc "map sbc documents"
  task :map_sbc, [:year] => :environment do |_t, args|
    year = args[:year]
    previous_year = year - 1
    puts "mapping sbc docs for #{year}" unless Rails.env.test?
    Plan.where(active_year: previous_year).each do |old_plan|
      new_plan = Plan.where(active_year: year, hios_id: old_plan.hios_id).first
      if new_plan.present?
        new_plan.sbc_document = old_plan.sbc_document
        new_plan.save
        puts "updated sbc document for old model #{year} #{new_plan.hios_id}" unless Rails.env.test?
      else
        puts "no plan present #{old_plan.hios_id}" unless Rails.env.test?
      end
    end

    ::BenefitMarkets::Products::Product.by_year(previous_year).each do |old_product|
      new_product = ::BenefitMarkets::Products::Product.where(
        hios_id: old_product.hios_id,
        benefit_market_kind: old_product.benefit_market_kind,
        metal_level_kind: old_product.metal_level_kind
      ).by_year(year).first
      if new_product.present?
        new_product.sbc_document = old_product.sbc_document
        new_product.save
        puts "updated sbc document for new model #{year} #{new_product.hios_id}" unless Rails.env.test?
      else
        puts "product not present: #{old_product.hios_id}"
      end
    end
  end
end
