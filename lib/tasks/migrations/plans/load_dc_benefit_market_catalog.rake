include EventSource::Command

namespace :load do
  task :dc_benefit_market_catalog, [:year] => :environment do |task, args|

    health_product_kinds = [:metal_level, :single_product, :single_issuer]
    dental_product_kinds = [:multi_product, :single_issuer]
    market_kinds = []
    market_kinds << :aca_shop if EnrollRegistry.feature_enabled?(:aca_shop_market)
    market_kinds << :fehb if EnrollRegistry.feature_enabled?(:fehb_market)
    market_kinds.each do |kind|

      benefit_market = BenefitMarkets::BenefitMarket.where(:site_urn => EnrollRegistry[:enroll_app].setting(:site_key).item, kind: kind).first

      calender_year = args[:year].present? ? args[:year].to_i : 2022

      puts "Creating #{kind.to_s} Benefit Market Catalog for #{calender_year}" unless Rails.env.test?

      benefit_market_catalog = benefit_market.benefit_market_catalogs.select{
        |a| a.application_period.first.year.to_s == calender_year.to_s
      }.first

      if benefit_market_catalog.present?
      else
        benefit_market_catalog = benefit_market.benefit_market_catalogs.create!({
          title: "#{Settings.aca.state_abbreviation} #{EnrollRegistry[:enroll_app].setting(:short_name).item} SHOP Benefit Catalog",
          application_interval_kind: :monthly,
          application_period: Date.new(calender_year,1,1)..Date.new(calender_year,12,31),
          probation_period_kinds: ::BenefitMarkets::PROBATION_PERIOD_KINDS
        })
      end

      congress_contribution_model = BenefitMarkets::ContributionModels::ContributionModel.where(title: "DC Congress Contribution Model").first.create_copy_for_embedding
      shop_contribution_model = BenefitMarkets::ContributionModels::ContributionModel.where(title: "DC Shop Simple List Bill Contribution Model").first.create_copy_for_embedding
      contribution_model = kind.to_s == "aca_shop" ? shop_contribution_model : congress_contribution_model
      pricing_model = BenefitMarkets::PricingModels::PricingModel.where(:name => "DC Shop Simple List Bill Pricing Model").first.create_copy_for_embedding


      def products_for(product_package, calender_year)
        product_class = product_package.product_kind.to_s== "health" ? BenefitMarkets::Products::HealthProducts::HealthProduct : BenefitMarkets::Products::DentalProducts::DentalProduct
        puts "Found #{product_class.by_product_package(product_package).count} #{product_package.product_kind.to_s} products for #{calender_year} #{product_package.package_kind.to_s}"
        product_class.by_product_package(product_package).collect { |prod| prod.create_copy_for_embedding }
      end

      if kind == :aca_shop && EnrollRegistry.feature?("aca_shop_osse_eligibility_#{calender_year}") && EnrollRegistry.feature_enabled?("aca_shop_osse_eligibility_#{calender_year}")
        puts "Creating eligibilities......"
        effective_date = benefit_market_catalog.application_period.min.to_date

        result = Operations::Eligible::CreateCatalogEligibility.new.call(
          {
            subject: benefit_market_catalog.to_global_id,
            eligibility_feature: "aca_shop_osse_eligibility",
            effective_date: effective_date,
            domain_model: "AcaEntities::BenefitSponsors::BenefitSponsorships::BenefitSponsorship"
          }
        )

        if result.success?
          p "Success: created eligibility for #{effective_date.year} benefit market catalog"

          puts "::: Creating SHOP OSSE eligibilities (This is Async)"
          puts ":::::::::::::::: THIS IS ASYNC PROCESS ::::::::::::::::"

          count = 0
          eligibility_date = effective_date - 1.day
          ::BenefitSponsors::BenefitSponsorships::BenefitSponsorship.all.no_timeout.each do |benefit_sponsorship|
            count += 1
            event = event('events.benefit_sponsors.osse_renewal', attributes: { gid: benefit_sponsorship.to_global_id.uri, eligibility_date: eligibility_date, effective_date: effective_date })
            if event.success?
              event.success.publish
            else
              puts "ERROR: Event trigger failed: benefit_sponsorship FEIN: #{benefit_sponsorship.fein}"
            end
            puts "Processsed #{count} SHOP OSSE eligibilities" if (count % 1000) == 0
          end
        else
          p "Failed to create eligibility for #{effective_date.year} benefit market catalog"
        end
      else
        puts "SHOP OSSE is disabled; Skipping catalog creation & benefit sponsorship renewal"
      end


      puts "Creating Product Packages..." unless Rails.env.test?

      [:health, :dental].each do |product_kind|
        (health_product_kinds + dental_product_kinds).uniq.each do |package_kind|
          if (product_kind.to_s == 'health' && health_product_kinds.include?(package_kind.to_sym)) || (product_kind.to_s == 'dental' && dental_product_kinds.include?(package_kind.to_sym))
            puts "Creating #{package_kind} Product Packages for #{product_kind}"

            product_package = benefit_market_catalog.product_packages.where(benefit_kind: kind, product_kind: product_kind, package_kind: package_kind).first_or_create
            product_package.title = package_kind.to_s.titleize,
            product_package.application_period = benefit_market_catalog.application_period,
            product_package.contribution_model = contribution_model,
            product_package.pricing_model = pricing_model

            product_package.products = products_for(product_package, calender_year)
            product_package.save! if product_package.valid? && product_package.products.present?
          end
        end
      end
    end
  end
end
