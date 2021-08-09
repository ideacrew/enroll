# frozen_string_literal: true

require File.join(Rails.root, 'lib/mongoid_migration_task')
# new rake task to update csr list
class MigrateThmCsrVariant < MongoidMigrationTask

  def process_families(families, logger, offset_count)
    families.no_timeout.limit(5_000).offset(offset_count).inject([]) do |_dummy, family|
      person = family.primary_person
      next unless person.present?
      family.active_household.tax_households.where(:"eligibility_determinations.csr_percent_as_integer".ne => nil).each do |thh|
        csr_percent_as_integer = thh.eligibility_determinations.last.csr_percent_as_integer
        thh.tax_household_members.where(:is_ia_eligible => true).each do |thhm|
          thhm.update_attributes!(csr_percent_as_integer: csr_percent_as_integer)
        end
      end
    rescue StandardError => e
      logger.info "error processing family with primary person hbx_id: #{person.hbx_id}, error: #{e.message}" unless Rails.env.test?
    end
  end

  def unprocessed_families(families, current_year)
    total_family_count = 0
    families.no_timeout.each do |family|
      tax_households = if current_year
                         family.active_household.tax_households.tax_household_with_year(2021)
                       else
                         family.active_household.tax_households
                       end
      tax_households.each do |thh|
        thh.tax_household_members.where(:is_ia_eligible => true).each do |thhm|
          total_family_count += 1 if thhm.csr_percent_as_integer.nil?
        end
      end
    end
    total_family_count
  end

  def migrate
    logger = Logger.new("#{Rails.root}/log/thhm_csr_update_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
    start_time = DateTime.current
    logger.info "IndividualthhmCsr start_time: #{start_time}" unless Rails.env.test?
    families = Family.all_tax_households
    latest_year_families = unprocessed_families(families, true)
    families_count = unprocessed_families(families, false)
    total_count = families.count
    logger.info "Total number of families to be processed #{total_count}"
    familes_per_iteration = 5_000.0
    number_of_iterations = (total_count / familes_per_iteration).ceil
    counter = 0

    while counter < number_of_iterations
      offset_count = familes_per_iteration * counter
      process_families(families, logger, offset_count)
      counter += 1
    end
    end_time = DateTime.current

    logger.info "Unprocessed families List: #{families_count}" unless Rails.env.test?
    logger.info "Unprocessed families List from current year: #{latest_year_families}" unless Rails.env.test?
    logger.info "IndividualthhmCsr end_time: #{end_time}, total_time_taken_in_minutes: #{((end_time - start_time) * 24 * 60).to_i}" unless Rails.env.test?
  end
end