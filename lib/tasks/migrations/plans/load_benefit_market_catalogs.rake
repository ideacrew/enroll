namespace :load do
  task :benefit_market_catalog => :environment do

    calender_year = 2019
    site = BenefitSponsors::Site.where(site_key: "#{Settings.site.subdomain}").first
    benefit_market = BenefitMarkets::BenefitMarket.where(:site_urn => Settings.site.key, kind: :aca_shop).first

    puts "Creating Benefit Market Catalog for #{calender_year}"

    benefit_market_catalog = benefit_market.benefit_market_catalogs.select{
      |a| a.application_period.first.year.to_s == calender_year.to_s
    }.first

    if benefit_market_catalog.present?
    else
      benefit_market_catalog = benefit_market.benefit_market_catalogs.create!({
        title: "#{Settings.aca.state_abbreviation} #{Settings.site.short_name} SHOP Benefit Catalog",
        application_interval_kind: :monthly,
        application_period: Date.new(calender_year,1,1)..Date.new(calender_year,12,31),
        probation_period_kinds: ::BenefitMarkets::PROBATION_PERIOD_KINDS
      })
    end

    composite_contribution_model = BenefitMarkets::ContributionModels::ContributionModel.where(title: "MA Composite Contribution Model").first.create_copy_for_embedding
    composite_pricing_model = BenefitMarkets::PricingModels::PricingModel.where(:name => "MA Composite Price Model").first.create_copy_for_embedding

    list_bill_contribution_model = BenefitMarkets::ContributionModels::ContributionModel.where(title: "MA List Bill Shop Contribution Model").first.create_copy_for_embedding
    list_bill_pricing_model = BenefitMarkets::PricingModels::PricingModel.where(:name => "MA List Bill Shop Pricing Model").first.create_copy_for_embedding

    def products_for(product_package, calender_year)
      puts "Found #{BenefitMarkets::Products::HealthProducts::HealthProduct.by_product_package(product_package).count} products for #{calender_year} #{product_package.package_kind.to_s}"
      BenefitMarkets::Products::HealthProducts::HealthProduct.by_product_package(product_package).collect { |prod| prod.create_copy_for_embedding }
    end

    puts "Creating Product Packages..."

    {"Single Issuer" => :single_issuer, "Metal Level" => :metal_level, "Single Product" => :single_product}.each do |title, package_kind|
      product_package = benefit_market_catalog.product_packages.where(title: title).first
      if product_package.present?
        product_package.products = []
      else
        product_package = benefit_market_catalog.product_packages.new({
          benefit_kind: :aca_shop, product_kind: :health, title: title,
          package_kind: package_kind,
          application_period: benefit_market_catalog.application_period,
          contribution_model: list_bill_contribution_model,
          pricing_model: list_bill_pricing_model
        })
      end
      product_package.products = products_for(product_package, calender_year)
      product_package.save! if product_package.valid?
    end

  end
end