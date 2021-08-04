# frozen_string_literal: true

# RAILS_ENV=production bundle exec rake

require File.join(Rails.root, "lib/mongoid_migration_task")
# New rake task to update csr variant on tax household member
class MigrateThmCsrVariant < MongoidMigrationTask

  def migrate
    families = Family.where(id: "61072f3a83d00d7fec2dc211")
    batch_size = 500
    offset = 0
    while offset <= families.count
      families.offset(offset).limit(batch_size).no_timeout.each do |family|
        begin
          family.no_timeout.each do |fam|
            if fam.nil? || fam.active_household.nil? || fam.active_household.latest_active_tax_household.nil?
              puts "No primary_family or active househod or latest_active_household exists for person with the given hbx_id #{fam.id}" unless Rails.env.test?
              next
            end
            active_household = fam.active_household
            latest_tax_household = active_household.latest_active_tax_household_with_year(TimeKeeper.date_of_record.year)
            if latest_tax_household.present? && latest_tax_household.latest_eligibility_determination.present?
              ed = latest_tax_household.latest_eligibility_determination
              csr_percent = ed.csr_percent_as_integer
              thhm = latest_tax_household.tax_household_members.where(is_ia_eligible: true)
              @logger.info "Tax household members not present for given tax household" if thhm.nil?
              if thhm.present?
                thhm.each do |thm|
                  thm.update(csr_percent_as_integer: csr_percent)
                end
              end
            end
            puts "Update csr variant for family of #{fam.primary_applicant.person.full_name}" unless Rails.env.test?
            @logger.info "End of the script" unless Rails.env.test?
          end
        rescue Exception => e
          puts "Update csr variant for family of" unless Rails.env.test?
        end
      end
      offset = offset + batch_size
      puts "offset count - #{offset}"
    end
  end
end