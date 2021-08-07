# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")
# New rake task to update csr variant on tax household member
# rubocop:disable Metrics/AbcSize
# rubocop:disable Metrics/CyclomaticComplexity
# rubocop:disable Metrics/PerceivedComplexity
class MigrateThmCsrVariant < MongoidMigrationTask

  def migrate
    @logger = Logger.new("#{Rails.root}/log/migrate_thm_csr_variant.log") unless Rails.env.test?
    Rails.logger.info "Script Start - #{TimeKeeper.datetime_of_record}" unless Rails.env.test?

    field_names = %w[Person_ID Family_Id Tax_Household_ID TH_Member_ID CSR_Percent_as_Integer]

    report_file_name = "#{Rails.root}/updated_csr_list_report_#{TimeKeeper.date_of_record.strftime('%m_%d_%Y')}.csv"
    logger_file_name = "#{Rails.root}/existing_csr_list_before_update_#{TimeKeeper.date_of_record.strftime('%m_%d_%Y')}.csv"

    CSV.open(logger_file_name, 'w', force_quotes: true) do |logger_csv|
      logger_csv << field_names
      CSV.open(report_file_name, 'w', force_quotes: true) do |report_csv|
        report_csv << field_names
        families = Family.all_tax_households
        batch_size = 500
        offset = 0
        while offset <= families.count
          families.offset(offset).limit(batch_size).no_timeout.each do |family|
            if family.nil? || family.active_household.nil? || family.active_household.tax_households.nil?
              puts "No primary_family or active househod or latest_active_household exists for person with the given hbx_id #{family.id}" unless Rails.env.test?
              next
            end

            family.active_household.tax_households.each do |tax_household|
              if tax_household.latest_eligibility_determination.nil? || tax_household.tax_household_members.nil?
                puts "No eligibility detemination or tax household members exists for person with the given hbx_id #{family.id}" unless Rails.env.test?
                next
              end
              ed = tax_household.latest_eligibility_determination # check two determinations created at determined
              Rails.logger.info "No Eligibility determinaton found for the family of - #{family.id}" if ed.nil?
              csr_percent = ed.csr_percent_as_integer

              thhms = tax_household.tax_household_members.where(is_ia_eligible: true)
              Rails.logger.info "Tax household members not present for given tax household of - #{family.id}" if thhms.nil?

              thhms&.each do |thm|
                Rails.logger.info "Csr Variant Before Update for - #{thm.id} - is - #{thm.csr_percent_as_integer}" unless Rails.env.test?
                logger_csv << [family.primary_applicant&.person_id&.to_s, family.id.to_s, tax_household.id.to_s, thm.id.to_s, thm.csr_percent_as_integer]
                thm.update_attributes!(csr_percent_as_integer: csr_percent)
                report_csv << [family.primary_applicant&.person_id&.to_s, family.id.to_s, tax_household.id.to_s, thm.id.to_s, thm.csr_percent_as_integer]
                Rails.logger.info "Updated csr variant for family for - #{thm.applicant_id} - is - #{thm.csr_percent_as_integer}" unless Rails.env.test?
              end
            end
            puts "Update csr variant for family of #{family.id.to_s}" unless Rails.env.test?
            Rails.logger.info "End of the script" unless Rails.env.test?
          end
          offset += batch_size
          puts "offset count - #{offset}"
        end
      end
    end
  rescue StandardError => e
    puts "error: #{e.message}" unless Rails.env.test?
  end
end
# rubocop:enable Metrics/AbcSize
# rubocop:enable Metrics/CyclomaticComplexity
# rubocop:enable Metrics/PerceivedComplexity