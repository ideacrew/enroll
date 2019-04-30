::BenefitSponsors::Organizations::Organization.issuer_profiles.delete_all
::BenefitMarkets::Locations::CountyZip.delete_all
::BenefitMarkets::Locations::RatingArea.delete_all
::BenefitMarkets::Locations::ServiceArea.delete_all
::BenefitMarkets::Products::Product.delete_all
::BenefitMarkets::ContributionModels::ContributionModel.delete_all
::BenefitMarkets::PricingModels::PricingModel.delete_all
::BenefitMarkets::BenefitMarketCatalog.delete_all

folder_path = "/Users/raghuram/MAHealthConnector/enroll/db/seedfiles/cca"

require File.expand_path(File.join(folder_path, "issuer_profiles_seed"))
Mongoid::Migration.say_with_time("Load MA Issuer Profiles") do
  load_cca_issuer_profiles_seed
end

require File.expand_path(File.join(folder_path, "locations_seed"))
Mongoid::Migration.say_with_time("Load MA County Zips") do
  load_cca_locations_county_zips_seed
end
Mongoid::Migration.say_with_time("Load MA Rating Areas") do
  load_ma_locations_rating_areas_seed
end
Mongoid::Migration.say_with_time("Load MA Service Areas") do
  load_ma_locations_service_areas_seed
end

require File.expand_path(File.join(folder_path, "products_seed"))
Mongoid::Migration.say_with_time("Load MA Products") do
  load_cca_products_seed
end

require File.expand_path(File.join(folder_path, "pricing_and_contribution_models_seed"))
Mongoid::Migration.say_with_time("Load MA Pricing Models") do
  load_cca_pricing_models_seed
end
Mongoid::Migration.say_with_time("Load MA Contribution Models") do
  load_cca_contribution_models_seed
end

require File.expand_path(File.join(folder_path, "benefit_market_catalogs_seed"))
Mongoid::Migration.say_with_time("Load MA Benefit Market Catalogs") do
  load_cca_benefit_market_catalogs_seed
end