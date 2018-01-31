namespace :users do
  desc "update oim_id of user by email"
  task :update_oim => :environment do 
    count = 0
    users = User.where(oim_id: nil).any_in(:roles => ['broker', 'hbx_staff', 'broker_agency_staff', 'general_agency_staff']).entries
    users.each do |user|
      if user.email.present?
        if user.update(oim_id: user.email)
          count += 1
        else
          puts "#{user.email} save error: #{user.errors.full_messages.join(',')}"
        end
      else
        puts "#{user.id} without email"
      end
    end
    puts "updated #{count} users for oim_id"
  end
end
