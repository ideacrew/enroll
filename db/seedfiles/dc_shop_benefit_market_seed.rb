require File.expand_path(File.join(File.dirname(__FILE__), "dc_pricing_and_contribution_models_seed.rb"))

benefit_market = ::BenefitMarkets::BenefitMarket.create!({
  kind: :aca_shop,
  title: "DC Health Link SHOP Market"
})

benefit_market_catalog = ::BenefitMarkets::BenefitMarketCatalog.create!({
  title: "DC Health Link SHOP Benefit Catalog",
  application_interval_kind: :monthly,
  benefit_market: benefit_market,
  application_period: Date.new(2018,1,1)..Date.new(2018,12,31),
  probation_period_kinds: ::BenefitMarkets::PROBATION_PERIOD_KINDS
})

dc_contribution_model = ::BenefitMarkets::ContributionModels::ContributionModel.where(name: "DC Shop Contribution Model").first
dc_pricing_model = ::BenefitMarkets::PricingModels::PricingModel.where(name: "DC Shop Pricing Model").first

plan_active_year = benefit_market_catalog.application_period.first.year

["bronze", "silver", "gold", "platinum"].each do |ml|
  if Plan.where(:metal_level => ml, :market => "shop", :coverage_kind => "health", :active_year => plan_active_year).any?
    ::BenefitMarkets::Products::HealthProducts::MetalLevelHealthProductPackage.create!({
      :metal_level => ml,
      :title => "DC Health #{ml.capitalize} Metal Level",
      :contribution_model_id => dc_contribution_model.id,
      :pricing_model_id => dc_pricing_model.id,
      :benefit_catalog => benefit_market_catalog
    })
  end
end

# Clean this up once we have migrated Plans => Products
Organization.where(carrier_profile: {"$ne" => nil}).each do |org|
  carrier_profile = org.carrier_profile
  if Plan.where(:carrier_profile_id => carrier_profile.id, :market => "shop", :coverage_kind => "health", :active_year => plan_active_year).any?
    ::BenefitMarkets::Products::HealthProducts::IssuerHealthProductPackage.create!({
      :issuer_id => carrier_profile.id,
      :title => "DC Health #{carrier_profile.legal_name} Issuer",
      :contribution_model_id => dc_contribution_model.id,
      :pricing_model_id => dc_pricing_model.id,
      :benefit_catalog => benefit_market_catalog
    })
  end
end

if Plan.where(:market => "shop", :coverage_kind => "health", :active_year => plan_active_year).any?
  ::BenefitMarkets::Products::HealthProducts::SingleProductHealthProductPackage.create!({
    :title => "DC Health Single Product",
    :contribution_model_id => dc_contribution_model.id,
    :pricing_model_id => dc_pricing_model.id,
    :benefit_catalog => benefit_market_catalog
  })
end

if Plan.where(:market => "shop", :coverage_kind => "dental", :active_year => plan_active_year).any?
  ::BenefitMarkets::Products::DentalProducts::AnyDentalProductPackage.create!({
    :title => "DC Dental Any Product",
    :contribution_model_id => dc_contribution_model.id,
    :pricing_model_id => dc_pricing_model.id,
    :benefit_catalog => benefit_market_catalog
  })
end
