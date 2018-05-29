glob_pattern = File.join(File.dirname(__FILE__), "fixtures", "benefit_market_catalogs", "*.yaml")

Mongoid::Migration.say_with_time("Load MA Benefit Market Catalogs") do
  Dir.glob(glob_pattern).each do |f_name|
    loaded_class1 = ::BenefitMarkets::BenefitMarketCatalog
    loaded_class2 = ::BenefitMarkets::ContributionModels::FixedPercentContributionUnit
    loaded_class3 = ::BenefitMarkets::PricingModels::RelationshipPricingUnit
    loaded_class4 = ::BenefitMarkets::PricingModels::TieredPricingUnit
    loaded_class5 = ::BenefitMarkets::Products::HealthProducts::HealthProduct
    loaded_class6 = ::BenefitMarkets::PricingModels::PricingUnit
    yaml_str = File.read(f_name)
    data = YAML.load(yaml_str)
    data.new_record = true
    data.save! rescue binding.pry
  end
end

