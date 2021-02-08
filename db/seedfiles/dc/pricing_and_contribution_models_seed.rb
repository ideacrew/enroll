def load_dc_shop_pricing_models_seed

  pm_pattern = File.join(File.dirname(__FILE__), "fixtures", "pricing_model_*.yaml")

  Dir.glob(pm_pattern).each do |f_name|
    loaded_class_1 = ::BenefitMarkets::PricingModels::PricingModel
    loaded_class_2 = ::BenefitMarkets::PricingModels::TieredPricingUnit
    loaded_class_3 = ::BenefitMarkets::PricingModels::RelationshipPricingUnit
    yaml_str = File.read(f_name)
    data = YAML.load(yaml_str)
    data.new_record = true

    data.save!
  end
end

def load_dc_shop_contribution_models_seed
  cm_pattern = File.join(File.dirname(__FILE__), "fixtures", "contribution_model_*.yaml")
  Dir.glob(cm_pattern).each do |f_name|
    loaded_class_1 = ::BenefitMarkets::ContributionModels::ContributionModel
    loaded_class_2 = ::BenefitMarkets::ContributionModels::FixedPercentContributionUnit
    loaded_class_3 = ::BenefitMarkets::ContributionModels::PercentWithCapContributionUnit
    yaml_str = File.read(f_name)
    data = YAML.load(yaml_str)
    data.new_record = true
    data.contribution_units.each do |cu|
      cu.contribution_model = data
      cu.member_relationship_maps.each do |member_relationship_map|
        member_relationship_map.contribution_unit = cu
      end
    end
    data.save!
  end
end