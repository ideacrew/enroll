require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateAptcAmount < MongoidMigrationTask
  def migrate
    start_date = Date.new(2017, 01, 01)
    end_date = Date.new(2017, 12, 31)
    families = Family.by_health_enrollments.all_assistance_receiving.by_enrollment_effective_date_range(start_date, end_date)
    count = 0

    families.each do |family|
      person = family.primary_applicant.person
      begin
        family.active_household.hbx_enrollments.by_year(2017).health.each do |en|
          ehb_premium = (en.plan.present? && en.plan.ehb > 0) ? (en.total_premium * en.plan.ehb).round(2) : en.total_premium

          if ehb_premium < en.applied_aptc_amount.to_f
            en.update_attributes!(:applied_aptc_amount, ehb_premium)
            puts "Primary Person's hbx_id: #{person.hbx_id}.The applied_aptc_amount: #{en.applied_aptc_amount}, ehb_premium: #{ehb_premium} for enr_hbx_id: #{en.hbx_id}" unless Rails.env.test?
            count += 1
          end
        end
      rescue => e
        puts "Bad family record #{family.id}, Reason: #{e.backtrace}" unless Rails.env.test?
      end
    end
    puts "Total number of updated records #{count}" unless Rails.env.test?
  end
end
