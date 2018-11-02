# loading of 2014, 2015 plans using plans.json file.
namespace :seed do
  desc "Load the carrier data"
  task :carriers => :environment do
    CarrierProfile.each do |carrier|
      carrier.delete
    end

    require File.join(Rails.root, "db/seedfiles/carriers_seed_#{Settings.aca.state_abbreviation.downcase}")
  end
end
