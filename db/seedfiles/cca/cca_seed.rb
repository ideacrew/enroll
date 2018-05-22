puts "Loading MA sites"
require File.join(File.dirname(__FILE__), "sites_seed")
puts "*"*80

puts "Loading MA issuer profiles"
require File.join(File.dirname(__FILE__), "issuer_profiles_seed")
puts "*"*80

puts "Loading MA contribution models"
require File.join(File.dirname(__FILE__),'..', 'ma_employer_pricing_and_contribution_models')
puts "*"*80
