namespace :migrations do
  desc "Update coverage start dates for renewal hbx enrollments"
  task :update_hbx_enrollment_members_coverage_dates => :environment do
    count = 0
    enrollment_count = 0

    Family.by_enrollment_shop_market.by_enrollment_renewing.each do |family|
      family.enrollments.renewing.each do |enrollment|
        enrollment_count += 1
        enrollment.hbx_enrollment_members.each do |member| 
          if member.coverage_start_on < enrollment.effective_on || member.eligibility_date < enrollment.effective_on
            member.update_attributes(coverage_start_on: enrollment.effective_on, eligibility_date: enrollment.effective_on)
            count += 1
          end
        end
      end
    end

    puts "Processed #{enrollment_count} enrollments."
    puts "Updated #{count} Hbx enrollment member records."
  end
end