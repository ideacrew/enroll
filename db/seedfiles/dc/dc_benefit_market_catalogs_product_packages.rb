Mongoid::Migration.say_with_time("Load DC Benefit Market Catalogs") do

  [:aca_shop, :fehb].each do |kind|

    benefit_market = BenefitMarkets::BenefitMarket.where(:site_urn => Settings.site.key, kind: kind).first

    [2014, 2015, 2016, 2017, 2018, 2019].each do |calender_year|

      puts "Creating #{kind.to_s} Benefit Market Catalog for #{calender_year}"
      benefit_market_catalog = benefit_market.benefit_market_catalogs.create!({
                                                                                  title: "#{Settings.aca.state_abbreviation} #{EnrollRegistry[:enroll_app].setting(:short_name).item} SHOP Benefit Catalog",
                                                                                  application_interval_kind: :monthly,
                                                                                  application_period: Date.new(calender_year,1,1)..Date.new(calender_year,12,31),
                                                                                  probation_period_kinds: ::BenefitMarkets::PROBATION_PERIOD_KINDS
                                                                              })
      congress_contribution_model = BenefitMarkets::ContributionModels::ContributionModel.where(title: "DC Congress Contribution Model").first.create_copy_for_embedding
      shop_contribution_model = BenefitMarkets::ContributionModels::ContributionModel.where(title: "DC Shop Simple List Bill Contribution Model").first.create_copy_for_embedding
      contribution_model = kind.to_s == "aca_shop" ? shop_contribution_model : congress_contribution_model
      pricing_model = BenefitMarkets::PricingModels::PricingModel.where(:name => "DC Shop Simple List Bill Pricing Model").first.create_copy_for_embedding

      def products_for(product_package, calender_year)
        product_class = product_package.product_kind.to_s== "health" ? BenefitMarkets::Products::HealthProducts::HealthProduct : BenefitMarkets::Products::DentalProducts::DentalProduct
        puts "Found #{product_class.by_product_package(product_package).count} #{product_package.product_kind.to_s} products for #{calender_year} #{product_package.package_kind.to_s}"
        product_class.by_product_package(product_package).collect { |prod| prod.create_copy_for_embedding }
      end

      def product_packages(market, product_kind)
        if market == :aca_shop
          product_kind == :health ? BenefitMarkets::Products::HealthProducts::HealthProduct::PRODUCT_PACKAGE_KINDS : BenefitMarkets::Products::DentalProducts::DentalProduct::PRODUCT_PACKAGE_KINDS
        else
          product_kind == :health ? BenefitMarkets::Products::HealthProducts::HealthProduct::CONGRESSIONAL_PRODUCT_PACKAGE_KINDS : []
        end
      end

      [:health, :dental].each do |product_kind|

        puts "Creating #{product_kind.to_s} Product Packages..."
        product_packages(kind, product_kind).each do |package_kind|
          product_package = benefit_market_catalog.product_packages.new({
                                                                            benefit_kind: kind, product_kind: product_kind, title: package_kind.to_s,
                                                                            package_kind: package_kind,
                                                                            application_period: benefit_market_catalog.application_period,
                                                                            contribution_model: contribution_model,
                                                                            pricing_model: pricing_model
                                                                        })

          product_package.products = products_for(product_package, calender_year)
          product_package.save! if product_package.valid? && product_package.products.present?
        end
      end
    end
  end
end
