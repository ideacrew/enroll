# loading of 2014, 2015 plans using plans.json file.
namespace :seed do
  desc "Load the carrier data"
  task :carriers => :environment do
    CarrierProfile.each do |carrier|
      carrier.delete
    end
    %w(010000000 020000000 030000000 040000000 050000000 060000000 070000000 080000000 090000000 001000000).each do |id|
      org = Organization.where(fein: id).first
      org.delete if org
    end
    require File.join(Rails.root, "db/seedfiles/carriers_seed")
  end
end
