# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")
# New rake task to update csr variant on tax household member
class MigrateThmCsrVariant < MongoidMigrationTask

  def migrate
    logger_field_names = %w[Family_ID Backtrace]
    logger_file_name = "#{Rails.root}/updated_csr_variant_logger_#{TimeKeeper.date_of_record.strftime('%m_%d_%Y')}.csv"

    families = Family.all_tax_households
    batch_size = 500
    processed_count = 0

    FileUtils.touch(logger_file_name) unless File.exist?(logger_file_name)
    CSV.open(logger_file_name, 'w', force_quotes: true) do |logger_csv|
      logger_csv << logger_field_names
      families.limit(batch_size).no_timeout.each do |family|
        family.active_household.tax_households.each do |tax_household|
          csr_percent = tax_household.latest_eligibility_determination.csr_percent_as_integer
          thhms = tax_household.tax_household_members.where(is_ia_eligible: true)
          thhms&.each do |thm|
            thm.update_attributes!(csr_percent_as_integer: csr_percent)
            puts "Updated csr variant for family for - #{thm.applicant_id} - is - #{thm.csr_percent_as_integer}"
            processed_count += 1
          end
        end
      rescue StandardError => e
        logger_csv << [family.id, e.backtrace[0..5].join('\n')]
      end
    end
    puts("Total records updated are #{processed_count}.")
  end
end