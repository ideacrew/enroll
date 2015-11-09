namespace :migrations do
  desc "Update renewned hbx enrollment members coverage start on dates"
  task :edit_hbx_enrollment_members_coverage_start_dates => :environment do

    families = Family.where("households.hbx_enrollments.aasm_state" => "auto_renewing")
    puts "found #{families.count} families in total."

    changed_count = 0
    families.each do |family|
      family.active_household.hbx_enrollments.each do |enrollment|
        if enrollment.auto_renewing?
          enrollment.hbx_enrollment_members.each do |member|
            member.coverage_start_on = Date.new(2016,1,1)
          end
          family.save!
          changed_count += 1
        end
      end
    end

    puts "updated #{changed_count} enrollments"
  end
end