namespace :seed do
  task :dental_contribution_and_pricing_model => :environment do

    Rake::Task['seed:load_pricing_model'].invoke
    Rake::Task['seed:load_contribution_model'].invoke
  end

  task :load_pricing_model => :environment do

    pm_pattern = File.join(Rails.root, "db", "seedfiles", "cca", "fixtures", "pricing_model_5b747fc2e2402363abcb7651.yaml")

    Dir.glob(pm_pattern).each do |f_name|
      loaded_class_1 = ::BenefitMarkets::PricingModels::PricingModel
      loaded_class_2 = ::BenefitMarkets::PricingModels::TieredPricingUnit
      loaded_class_3 = ::BenefitMarkets::PricingModels::RelationshipPricingUnit
      yaml_str = File.read(f_name)
      data = YAML.load(yaml_str)

      next unless data.price_calculator_kind.gsub(/^.*::/, '') == "ShopSimpleListBillPricingCalculator"
      data.new_record = true
      data.save!
    end
  end

  task :load_contribution_model => :environment do

    cm_pattern = File.join(Rails.root, "db", "seedfiles", "cca", "fixtures", "contribution_model_5b747fe2e2402363abcb765e.yaml")

    Dir.glob(cm_pattern).each do |f_name|
      loaded_class_1 = ::BenefitMarkets::ContributionModels::ContributionModel
      loaded_class_2 = ::BenefitMarkets::ContributionModels::FixedPercentContributionUnit
      yaml_str = File.read(f_name)
      data = YAML.load(yaml_str)

      next unless data.contribution_calculator_kind.gsub(/^.*::/, '') == "SimpleShopReferencePlanContributionCalculator"
      data.new_record = true
      data.save!
    end
  end
end