# these rake tasks should only be run for mocking 2021 data, these should not be run for anything else.

namespace :new_model do

  desc "new model mock data rake tasks"
  task :mock_data => :environment do
    puts "game started" unless Rails.env.test?
    Rake::Task['new_model:rating_areas'].invoke
    Rake::Task['new_model:service_areas'].invoke

    puts "loading 2021 plans" unless Rails.env.test?
    Rake::Task['xml:plans'].invoke

    Rake::Task['new_model:rating_factors'].invoke
    Rake::Task['new_model:plan_cross_walk'].invoke

    # puts "updating provider/rx formulary urls, marking standard and network info " unless Rails.env.test?
    # Rake::Task['import:common_data_from_master_xml'].invoke

    puts "loading 2021 rates" unless Rails.env.test?
    Rake::Task['xml:rates'].invoke

    puts "loading 2021 benefit market catalog" unless Rails.env.test?
    Rake::Task['load:dc_benefit_market_catalog'].invoke

    puts "loading 2021 ivl benefit pacakges" unless Rails.env.test?
    Rake::Task['import:create_2021_ivl_packages'].invoke

    # Rake::Task['new_model:map_sbc'].invoke
  end

  desc "rating factors"
  task :rating_factors => :environment do
    if Settings.site.key.to_s == "dc"
      [2021].each do |year|
        puts "creating rating factors for #{year}" unless Rails.env.test?
        ::BenefitSponsors::Organizations::Organization.issuer_profiles.each do |issuer_organization|
          issuer_profile = issuer_organization.issuer_profile
            # participation rate factor
          ::BenefitMarkets::Products::ActuarialFactors::ParticipationRateActuarialFactor.create!(
              active_year: year,
              default_factor_value: 1.0,
              max_integer_factor_key: 100,
              issuer_profile_id: issuer_profile.id,
              actuarial_factor_entries: []
          )
          # group size factor
          ::BenefitMarkets::Products::ActuarialFactors::GroupSizeActuarialFactor.create!(
              active_year: year,
              default_factor_value: 1.0,
              max_integer_factor_key: 1,
              issuer_profile_id: issuer_profile.id,
              actuarial_factor_entries: []
          )
        end
      end
    end
  end

  desc "service areas"
  task :service_areas => :environment do
    if Settings.site.key.to_s == "dc"
      [2021].each do |year|
        puts "Creating Service areas for new model #{year}" unless Rails.env.test?
        ::BenefitSponsors::Organizations::Organization.issuer_profiles.each do |issuer_organization|
          issuer_profile = issuer_organization.issuer_profile
          issuer_profile.issuer_hios_ids.each do |issuer_hios_id|
            ::BenefitMarkets::Locations::ServiceArea.create!({
               active_year: year,
               issuer_provided_code: "DCS001",
               covered_states: ["DC"],
               county_zip_ids: [],
               issuer_profile_id: issuer_profile.id,
               issuer_hios_id: issuer_hios_id,
               issuer_provided_title: issuer_profile.legal_name
            })
          end
        end
      end
    end
  end

  desc "rating areas"
    task :rating_areas => :environment do
    if Settings.site.key.to_s == "dc"
      [2021].each do |year|
        puts "Creating Rating areas for new model #{year}" unless Rails.env.test?
        ::BenefitMarkets::Locations::RatingArea.create!({
          active_year: year,
          exchange_provided_code: 'R-DC001',
          county_zip_ids: [],
          covered_states: ['DC']
        })
      end
    end
  end

  # map sbc documents
  desc "map sbc documents"
  task :map_sbc => :environment do
    puts "mapping sbc docs for 2021" unless Rails.env.test?
    Plan.where(active_year: 2020).each do |old_plan|
      new_plan = Plan.where(active_year: 2021, hios_id: old_plan.hios_id).first
      if new_plan.present?
        new_plan.sbc_document = old_plan.sbc_document
        new_plan.save
        puts "updated sbc document for old model 2021 #{new_plan.hios_id}" unless Rails.env.test?
      else
        puts "no plan present #{old_plan.hios_id}" unless Rails.env.test?
      end
    end

    ::BenefitMarkets::Products::Product.by_year(2020).each do |old_product|
      new_product = ::BenefitMarkets::Products::Product.where(
        hios_id: old_product.hios_id,
        benefit_market_kind: old_product.benefit_market_kind,
        metal_level_kind: old_product.metal_level_kind,
        ).by_year(2021).first
      if new_product.present?
        new_product.sbc_document = old_product.sbc_document
        new_product.save
        puts "updated sbc document for new model 2021 #{new_product.hios_id}" unless Rails.env.test?
      else
        puts "product not present: #{old_product.hios_id}"
      end
    end
  end

  # plan cross walk
  desc "Import plan crosswalk"
  task :plan_cross_walk => :environment do
    puts "mapping plans from 2020 -> 2011" unless Rails.env.test?
    # old plans
    Plan.where(active_year: 2020).each do |old_plan|
      new_plan = Plan.where(active_year: 2021, hios_id: old_plan.hios_id).first
      if new_plan.present?
        old_plan.renewal_plan_id = new_plan.id
        old_plan.save
        puts "Old #{old_plan.active_year} plan hios_id #{old_plan.hios_id} renewed with New #{new_plan.hios_id} plan hios_id: #{new_plan.hios_id}" unless Rails.env.test?
      end
    end
    # end old plans
    ::BenefitMarkets::Products::Product.by_year(2020).each do |old_product|
      new_product = ::BenefitMarkets::Products::Product.where(
        hios_id: old_product.hios_id,
        benefit_market_kind: old_product.benefit_market_kind,
        metal_level_kind: old_product.metal_level_kind,
        ).by_year(2021).first
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
end