site = BenefitSponsors::Site.where(site_key: "#{Settings.site.subdomain}").first

benefit_market = BenefitMarkets::BenefitMarket.where(:site_urn => Settings.site.key, kind: :aca_shop).first

puts "Creating Benefit Market Catalog..."
benefit_market_catalog = benefit_market.benefit_market_catalogs.create!({
  title: "#{Settings.aca.state_abbreviation} #{Settings.site.short_name} SHOP Benefit Catalog",
  application_interval_kind: :monthly,
  application_period: Date.new(2018,1,1)..Date.new(2018,12,31),
  probation_period_kinds: ::BenefitMarkets::PROBATION_PERIOD_KINDS
})

composite_contribution_model = BenefitMarkets::ContributionModels::ContributionModel.where(title: "MA Composite Contribution Model").first
composite_pricing_model = BenefitMarkets::PricingModels::PricingModel.where(:name => "MA Composite Price Model").first

list_bill_contribution_model = BenefitMarkets::ContributionModels::ContributionModel.where(title: "MA List Bill Shop Contribution Model").first
list_bill_pricing_model = BenefitMarkets::PricingModels::PricingModel.where(:name => "MA List Bill Shop Pricing Model").first


def products_for(kind)
  BenefitMarkets::Products::HealthProducts::HealthProduct.where(:product_package_kinds => /#{kind}/).to_a
end

puts "Creating Product Packages..."
benefit_market_catalog.product_packages.create!({ 
  benefit_kind: :aca_shop, product_kind: :health, title: 'Single Issuer', 
  package_kind: :single_issuer, 
  application_period: benefit_market_catalog.application_period,
  contribution_model: list_bill_contribution_model,
  pricing_model: list_bill_pricing_model,
  products: products_for('single_issuer')
  })

benefit_market_catalog.product_packages.create!({ 
  benefit_kind: :aca_shop, product_kind: :health, title: 'Metal Level', 
  package_kind: :metal_level, 
  application_period: benefit_market_catalog.application_period,
  contribution_model: list_bill_contribution_model,
  pricing_model: list_bill_pricing_model,
  products: products_for('metal_level')
})

benefit_market_catalog.product_packages.create!({
  benefit_kind: :aca_shop, product_kind: :health, title: 'Single Product', 
  package_kind: :single_product, 
  application_period: benefit_market_catalog.application_period,
  contribution_model: composite_contribution_model,
  pricing_model: composite_pricing_model,
  products: products_for('single_product')
})