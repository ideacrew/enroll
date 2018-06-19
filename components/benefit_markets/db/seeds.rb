## Populate namespaced seed content in this file
## To run:
##  1) In spec/dummy/db folder, create seed.rb file with following: BenefitMarkets::Engine.load_seed
##  2) In terminal, chdir to spec/dummy, run rake db:seed

require 'mongoid_rails_migrations'

puts "\n"*3
puts "Start of Engine BenefitMarkets seed"
puts "*"*80

collection_names = %w(
    benefit_markets_benefit_markets
    benefit_markets_benefit_market_catalogs
    benefit_markets_pricing_models_pricing_models
    benefit_markets_locations_service_areas
    benefit_markets_locations_rating_areas
    benefit_markets_contribution_models_contribution_models
    benefit_markets_locations_county_zips
    benefit_markets_products_products
    benefit_markets_products_actuarial_factors_actuarial_factors
  )

puts "Dropping engine-specific collections"
Mongoid.default_client.collections.each do |collection|
  if collection_names.include?(collection.name)
    puts "  dropping collection: #{collection.name}"
    collection.drop
  end
end
puts "*"*80
puts "*"*80

require File.join(File.dirname(__FILE__),'seedfiles', 'cca_seed')

puts "End of Engine BenefitMarkets seed"
puts "*"*80
