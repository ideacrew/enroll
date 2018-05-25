glob_pattern = File.join(File.dirname(__FILE__), "fixtures", "benefit_market_catalogs", "*.yaml")

Mongoid::Migration.say_with_time("Load MA Benefit Market Catalogs") do
  Dir.glob(glob_pattern).each do |f_name|
    loaded_class = ::BenefitMarkets::BenefitMarketCatalog
    yaml_str = File.read(f_name)
    data = YAML.load(yaml_str)
    data.new_record = true
    data.save! rescue binding.pry
  end
end

