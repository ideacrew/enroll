require File.join(Rails.root, "lib/mongoid_migration_task")
require 'csv'

class UpdateAptcAmount < MongoidMigrationTask
  def migrate
    field_names  = %w(
          Subscriber_FN
          Subscriber_LN
          HBX_ID
          Enrollment_hbx_id
          Enrollment_applied_aptc
         )
    start_date = Date.new(2017, 01, 01)
    end_date = Date.new(2017, 12, 31)
    families = Family.by_health_enrollments.all_assistance_receiving.by_enrollment_effective_date_range(start_date, end_date)
    total_count = families.count
    offset_count = 0
    limit_count = 500
    count = 0
    file_name = "#{Rails.root}/report_of_enrollments_with_updated_applied_aptc.csv"

    CSV.open(file_name, "w", force_quotes: true) do |csv|
      csv << field_names
      while (offset_count <= total_count) do
        families.limit(limit_count).offset(offset_count).each do |family|
          person = family.primary_applicant.person
          begin
            family.active_household.hbx_enrollments.by_year(2017).health.each do |en|
              ehb_premium = (en.plan.present? && en.plan.ehb > 0) ? (en.total_premium * en.plan.ehb).round(2) : en.total_premium

              if ehb_premium < en.applied_aptc_amount.to_f
                en.update_attributes!(:applied_aptc_amount, ehb_premium)
                csv << [
                  person.first_name,
                  person.last_name,
                  person.hbx_id,
                  en.hbx_id,
                  en.applied_aptc_amount
                 ]
                puts "Primary Person's hbx_id: #{person.hbx_id}.The applied_aptc_amount: #{en.applied_aptc_amount}, ehb_premium: #{ehb_premium} for enr_hbx_id: #{en.hbx_id}" unless Rails.env.test?
                count += 1
              end
            end
          rescue
            puts "Bad family record #{family.id}" unless Rails.env.test?
          end
        end
        offset_count += limit_count
      end
      puts "Total number of updated records #{count}" unless Rails.env.test?
    end
  end
end
