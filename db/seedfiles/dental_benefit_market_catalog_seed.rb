Mongoid::Migration.say_with_time("Updating MA Benefit Market Catalogs with Dental packages") do

  site = BenefitSponsors::Site.where(site_key: "#{Settings.site.subdomain}").first

  benefit_market = BenefitMarkets::BenefitMarket.where(:site_urn => Settings.site.key, kind: :aca_shop).first

  [2018].each do |calender_year|

    benefit_market_catalog = benefit_market.benefit_market_catalog_effective_on(Date.new(calender_year, 1, 1))

    list_bill_contribution_model = BenefitMarkets::ContributionModels::ContributionModel.where(title: "MA Shop Simple List Bill Contribution Model").first.create_copy_for_embedding
    list_bill_pricing_model = BenefitMarkets::PricingModels::PricingModel.where(:name => "MA Shop Simple List Bill Pricing Model").first.create_copy_for_embedding

    def products_for(product_package, calender_year)
      puts "Found #{BenefitMarkets::Products::DentalProducts::DentalProduct.by_product_package(product_package).count} products for #{calender_year} #{product_package.package_kind.to_s}"
      BenefitMarkets::Products::DentalProducts::DentalProduct.by_product_package(product_package).collect { |prod| prod.create_copy_for_embedding }
    end

    # puts "Creating Product Packages..."
    # product_package = benefit_market_catalog.product_packages.new({
    #   benefit_kind: :aca_shop, product_kind: :dental, title: 'Multi Product',
    #   package_kind: :multi_product,
    #   application_period: benefit_market_catalog.application_period,
    #   contribution_model: list_bill_contribution_model,
    #   pricing_model: list_bill_pricing_model
    # })

    # product_package.products = products_for(product_package, calender_year)
    # product_package.save! if product_package.valid?

    product_package = benefit_market_catalog.product_packages.new({
      benefit_kind: :aca_shop, product_kind: :dental, title: 'Single Product',
      package_kind: :single_product,
      application_period: benefit_market_catalog.application_period,
      contribution_model: list_bill_contribution_model,
      pricing_model: list_bill_pricing_model
    })

    product_package.products = products_for(product_package, calender_year)
    product_package.save! if product_package.valid?
  end
end
