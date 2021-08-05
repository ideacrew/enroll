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
    families = Family.all
    batch_size = 500
    offset = 0
    while offset <= families.count
      families.offset(offset).limit(batch_size).no_timeout.each do |family|
        if family.nil? || family.active_household.nil? || family.active_household.latest_active_tax_household.nil?
          puts "No primary_family or active househod or latest_active_household exists for person with the given hbx_id #{family.id}" unless Rails.env.test?
          next
        end
        active_household = family.active_household
        latest_tax_household = active_household.latest_active_tax_household_with_year(TimeKeeper.date_of_record.year)
        if latest_tax_household.present? && latest_tax_household.latest_eligibility_determination.present?
          ed = latest_tax_household.latest_eligibility_determination
          Rails.logger.info "No Eligibility determinaton found for the family of - #{family.primary_applicant.person.full_name}" if ed.nil?
          csr_percent = ed.csr_percent_as_integer
          thhm = latest_tax_household.tax_household_members.where(is_ia_eligible: true)
          Rails.logger.info "Tax household members not present for given tax household" if thhm.nil?
          thhm&.each do |thm|
            thm.update(csr_percent_as_integer: csr_percent)
            Rails.logger.info "Updated csr variant for family of - #{family.primary_applicant.person.full_name}" unless Rails.env.test?
          end
        end
        puts "Update csr variant for family of #{family.primary_applicant.person.full_name}" unless Rails.env.test?
        Rails.logger.info "End of the script" unless Rails.env.test?
      end
      offset += batch_size
      puts "offset count - #{offset}"
    end
  end
end
# rubocop:enable Metrics/AbcSize
# rubocop:enable Metrics/CyclomaticComplexity
# rubocop:enable Metrics/PerceivedComplexity