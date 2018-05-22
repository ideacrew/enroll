require File.expand_path(File.join(File.dirname(__FILE__), "site_seed"))
require File.expand_path(File.join(File.dirname(__FILE__), "issuer_profiles_seed"))
require File.expand_path(File.join(File.dirname(__FILE__), "benefit_markets_seed"))
Mongoid::Migration.say_with_time("Loading MA Contribution and Pricing Models") do
  require File.expand_path(File.join(File.dirname(__FILE__),'..', 'ma_employer_pricing_and_contribution_models'))
end
