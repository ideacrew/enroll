# frozen_string_literal: true

require File.join(Rails.root, 'lib/mongoid_migration_task')

# This class is for migrating TaxHousehold, TaxHouseholdMember, EligibilityDetermination of Household to TaxHousholdGroup, TaxHousehold, TaxhousholdMember models.
class MigrateHouseholdThhsToThhGroupThhs < MongoidMigrationTask
  def process_active_thhs_of_household(family, active_thhs_of_household)
    active_thhs_of_household.group_by(&:group_by_year).each do |_year, active_thhs_by_year|
      family = build_thhg_thhs_and_thhms(family, active_thhs_by_year)
    end
    family
  end

  def process_inactive_thhs_of_household(family, inactive_thhs_of_household)
    inactive_thhs_of_household.group_by(&:group_by_year).each do |_year, thhs_by_year|
      thhs_by_year.group_by{ |thh| thh.latest_eligibility_determination&.determined_at&.to_date }.each do |_year, thhs_by_determined_on|
        family = build_thhg_thhs_and_thhms(family, thhs_by_determined_on)
      end
    end
    family
  end

  # Builds tax_household_group, tax_households and tax_household_members
  def build_thhg_thhs_and_thhms(family, thhs_of_household)
    start_on = thhs_of_household.pluck(:effective_starting_on).compact.first
    effective_ending_on = thhs_of_household.pluck(:effective_ending_on).compact.first
    end_on = if effective_ending_on.present? && (effective_ending_on <= start_on)
               start_on
             else
               effective_ending_on
             end

    thhg = family.tax_household_groups.build
    thhg.source = thhs_of_household.map(&:latest_eligibility_determination).flat_map(&:source).compact.first
    thhg.start_on = start_on
    thhg.end_on = end_on
    thhg.assistance_year = start_on&.year
    thhg.determined_on = thhs_of_household.map(&:latest_eligibility_determination).flat_map(&:determined_at).compact.first
    build_ths_and_thhms(thhs_of_household, thhg)
    family
  end

  # Builds tax_households and tax_household_members for a given tax_household_group
  def build_ths_and_thhms(thhs_of_household, thhg)
    thhs_of_household.each do |thh|
      effective_ending_on = if thh.effective_ending_on.present? && (thh.effective_ending_on <= thh.effective_starting_on)
                              thh.effective_starting_on
                            else
                              thh.effective_ending_on
                            end

      thh_params = {
        effective_starting_on: thh.effective_starting_on,
        effective_ending_on: effective_ending_on,
        max_aptc: thh.latest_eligibility_determination.max_aptc
        # monthly_expected_contribution: ,
        # determination_id: ,
      }

      new_thh = thhg.tax_households.build(thh_params)
      build_thhms(thh.tax_household_members, new_thh)
    end
  end

  # Builds tax_household_members for a given tax_household
  def build_thhms(thhms, new_thh)
    thhms.each do |thhm|
      new_thh.tax_household_members.build(
        thhm.attributes.slice(:applicant_id, :is_ia_eligible, :is_medicaid_chip_eligible, :is_totally_ineligible,
                              :is_uqhp_eligible, :is_subscriber, :reason, :is_non_magi_medicaid_eligible,
                              :magi_as_percentage_of_fpl, :magi_medicaid_type, :magi_medicaid_category,
                              :magi_medicaid_monthly_household_income, :magi_medicaid_monthly_income_limit,
                              :medicaid_household_size, :is_without_assistance, :csr_percent_as_integer,
                              :csr_eligibility_kind)
      )
    end
    new_thh
  end

  def process_families(families, file_name, offset_count, logger)
    field_names = %w[primary_person_hbx_id family_hbx_assigned_id aptc_csr_tax_households_count group_premium_credits_count]

    CSV.open(file_name, 'w', force_quotes: true) do |csv|
      csv << field_names

      families.no_timeout.limit(5_000).offset(offset_count).inject([]) do |_dummy, family|
        logger.info "---------- Processing Family with family_hbx_assigned_id: #{family.hbx_assigned_id}"
        unless family.valid?
          logger.info "----- Invalid family with family_hbx_assigned_id: #{family.hbx_assigned_id}, errors: #{family.errors.full_messages}"
          next family
        end

        active_thhs_of_household = family.active_household.tax_households.active_tax_household
        family = process_active_thhs_of_household(family, active_thhs_of_household)

        inactive_thhs_of_household = family.active_household.tax_households.where(:effective_ending_on.ne => nil)
        family = process_inactive_thhs_of_household(family, inactive_thhs_of_household)

        if family.save
          logger.info "----- Successfully created TaxHouseholdGroups for family with family_hbx_assigned_id: #{family.hbx_assigned_id}"
        else
          logger.info "----- Errors persisting family with family_hbx_assigned_id: #{family.hbx_assigned_id}, errors: #{family.errors.full_messages}"
        end

        csv << [family.primary_person.hbx_id, family.hbx_assigned_id, family.active_household.tax_households.count, family.reload.tax_household_groups.map(&:tax_households).flatten.count]
      rescue StandardError => e
        logger.info "----- Error raised processing family with family_hbx_assigned_id: #{family.hbx_assigned_id}, error: #{e}, backtrace: #{e.backtrace.join('\n')}"
      end
    end
  end

  def migrate
    logger = Logger.new("#{Rails.root}/log/migrate_household_thhs_to_thh_group_thhs_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
    start_time = DateTime.current
    logger.info "MigrateHouseholdThhsToThhGroupThhs start_time: #{start_time}"
    families = Family.all_tax_households
    total_count = families.count
    familes_per_iteration = 5_000.0
    number_of_iterations = (total_count / familes_per_iteration).ceil
    counter = 0

    while counter < number_of_iterations
      file_name = "#{Rails.root}/household_thhs_to_thh_group_thhs_migration_list_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}_#{counter + 1}.csv"
      offset_count = familes_per_iteration * counter
      process_families(families, file_name, offset_count, logger)
      counter += 1
    end
    end_time = DateTime.current
    logger.info "MigrateHouseholdThhsToThhGroupThhs end_time: #{end_time}, total_time_taken_in_minutes: #{((end_time - start_time) * 24 * 60).to_f.ceil}" unless Rails.env.test?
  end
end
