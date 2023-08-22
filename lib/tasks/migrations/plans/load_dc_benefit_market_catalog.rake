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

          puts "::: Creating SHOP OSSE eligibilities"

          count = 0
          ::BenefitSponsors::BenefitSponsorships::BenefitSponsorship.where(:"eligibilities.key" => "aca_shop_osse_eligibility_#{calender_year}".to_sym).each do |benefit_sponsorship|
            count += 1
            start_on = effective_date - 1.day
            eligibility = benefit_sponsorship.eligibility_for("aca_shop_osse_eligibility_#{start_on.year}".to_sym, start_on)
            osse_eligibility = eligibility.blank? ? false : eligibility.is_eligible_on?(start_on)

            result = ::BenefitSponsors::Operations::BenefitSponsorships::ShopOsseEligibilities::CreateShopOsseEligibility.new.call(
              {
                subject: benefit_sponsorship.to_global_id,
                evidence_key: :shop_osse_evidence,
                evidence_value: osse_eligibility.to_s,
                effective_date: effective_date
              }
            )
            unless result.success?
              puts "Failed to create OSSE shop eligibility for benefit_sponsorship with id: #{benefit_sponsorship.id}"
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
