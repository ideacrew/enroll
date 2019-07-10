namespace :update_aptc do
  desc "update applied aptc amount by elected amount in hbx_enrollments"
  task :applied_aptc_amount => :environment do 
    count = 0
    families = Family.gt("households.hbx_enrollments.elected_amount.cents"=> 0).to_a
    families.each do |family|
      households = family.households.gt("hbx_enrollments.elected_amount.cents"=> 0).to_a
      households.each do |household|
        hbxs = household.hbx_enrollments.gt("elected_amount.cents"=> 0).to_a
        hbxs.each do |hbx|
          if hbx.elected_amount > 0 and hbx.applied_aptc_amount == 0
            hbx.update_current(applied_aptc_amount: hbx.elected_amount.to_f) 
            count += 1
          end
        end
      end
    end
    puts "updated #{count} hbx_enrollments for applied_aptc_amount"
  end
end
