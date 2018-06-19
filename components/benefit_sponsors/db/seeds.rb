## Populate namespaced seed content in this file
## To run:
##  1) In spec/dummy/db folder, create seed.rb file with following: BenefitSponsors::Engine.load_seed
##  2) In terminal, chdir to spec/dummy, run rake db:seed

require 'mongoid_rails_migrations'

puts "\n"*3
puts "Start of Engine BenefitSponsors seed"
puts "*"*80

collection_names = %w(
    benefit_sponsors_benefit_sponsorships_benefit_sponsorships
    benefit_sponsors_organizations_organizations
    benefit_sponsors_sites
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

puts "End of Engine BenefitSponsors seed"
puts "*"*80
