namespace :carriers do

  desc "Seed the production database"
  task :update_for_sole_source => :environment do
    ['53e67210eb899a4603000029', '53e67210eb899a4603000037'].each do |carrier_profile_id|
      carrier = CarrierProfile.find(carrier_profile_id)
      carrier.offers_sole_source = true
      carrier.save!
  end

end
