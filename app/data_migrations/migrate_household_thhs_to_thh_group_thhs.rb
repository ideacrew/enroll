# frozen_string_literal: true

require File.join(Rails.root, 'lib/mongoid_migration_task')

# This class is for migrating TaxHousehold, TaxHouseholdMember, EligibilityDetermination of Household to TaxHousholdGroup, TaxHousehold, TaxhousholdMember models.
class MigrateHouseholdThhsToThhGroupThhs < MongoidMigrationTask
  def process_active_thhs_of_household(family, active_thhs_of_household)
    active_thhs_of_household.group_by(&:group_by_year).each do |_year, active_thhs_by_year|
      family = build_thhg_thhs_and_thhms(family, active_thhs_by_year, false)
    end
    family
  end

  def process_inactive_thhs_of_household(family, inactive_thhs_of_household, set_external_effective_ending_on)
    inactive_thhs_of_household.group_by(&:group_by_year).each do |_year, thhs_by_year|
      thhs_by_year.group_by{ |thh| thh.latest_eligibility_determination&.determined_at&.to_date }.each do |_year, thhs_by_determined_on|
        family = build_thhg_thhs_and_thhms(family, thhs_by_determined_on, set_external_effective_ending_on)
      end
    end
    family
  end

  # Builds tax_household_group, tax_households and tax_household_members
  def build_thhg_thhs_and_thhms(family, thhs_of_household, set_external_effective_ending_on)
    start_on = thhs_of_household.pluck(:effective_starting_on).compact.first
    effective_ending_on = if set_external_effective_ending_on.present?
                            start_on
                          else
                            thhs_of_household.pluck(:effective_ending_on).compact.first
                          end

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
        max_aptc: thh.latest_eligibility_determination.max_aptc,
        yearly_expected_contribution: calculate_yearly_expected_contribution(thh, thh.family) || thh.yearly_expected_contribution
      }

      new_thh = thhg.tax_households.build(thh_params)
      build_thhms(thh.tax_household_members, new_thh)
    end
  end

  def calculate_yearly_expected_contribution(thh, family)
    applications = ::FinancialAssistance::Application.where(family_id: family.id).determined.where(:'eligibility_determinations.determined_at' => thh.created_at.to_date)

    if applications.size == 1
      application = applications.first
      annual_tax_household_income = application.eligibility_determinations.sum(&:aptc_csr_annual_household_income)
      total_household_count = application.applicants.size
      fpl_data = fp_levels[application.assistance_year]

      total_annual_poverty_guideline = fpl_data[:annual_poverty_guideline] +
                                       ((total_household_count - 1) * fpl_data[:annual_per_person_amount])
      fpl_percentage = (annual_tax_household_income.div(total_annual_poverty_guideline, 0) * 100).floor(2)

      annual_tax_household_income * applicable_percentage(fpl_percentage)
    else
      @logger.info "----- Failed to update Yearly Expected Contribution for family with family_hbx_assigned_id: #{family.hbx_assigned_id}. Found #{applications.size} applications"
      @app_ambiguity_hbx_ids << family.hbx_assigned_id
      nil
    end
  end

  def applicable_percentage(fpl_percentage)
    if fpl_percentage < 150
      BigDecimal('0')
    elsif fpl_percentage >= 150 && fpl_percentage < 200
      ((fpl_percentage - BigDecimal('150')) / BigDecimal('50')) * BigDecimal('2')
    elsif fpl_percentage >= 200 && fpl_percentage < 250
      (((fpl_percentage - BigDecimal('200')) / BigDecimal('50')) * BigDecimal('2')) + BigDecimal('2')
    elsif fpl_percentage >= 250 && fpl_percentage < 300
      (((fpl_percentage - BigDecimal('250')) / BigDecimal('50')) * BigDecimal('2')) + BigDecimal('4')
    elsif fpl_percentage >= 300 && fpl_percentage < 400
      (((fpl_percentage - BigDecimal('300')) / BigDecimal('100')) * BigDecimal('2.5')) + BigDecimal('6')
    else
      # covers 400 and above
      BigDecimal('8.5')
    end.div(BigDecimal('100'), 3)
  end

  def fp_levels
    {
      2013 => {
        annual_poverty_guideline: BigDecimal(11_490.to_s),
        annual_per_person_amount: BigDecimal(4_020.to_s)
      },
      2014 => {
        annual_poverty_guideline: BigDecimal(11_670.to_s),
        annual_per_person_amount: BigDecimal(4_060.to_s)
      },
      2015 => {
        annual_poverty_guideline: BigDecimal(11_770.to_s),
        annual_per_person_amount: BigDecimal(4_160.to_s)
      },
      2016 => {
        annual_poverty_guideline: BigDecimal(11_880.to_s),
        annual_per_person_amount: BigDecimal(4_160.to_s)
      },
      2017 => {
        annual_poverty_guideline: BigDecimal(12_060.to_s),
        annual_per_person_amount: BigDecimal(4_180.to_s)
      },
      2018 => {
        annual_poverty_guideline: BigDecimal(12_140.to_s),
        annual_per_person_amount: BigDecimal(4_320.to_s)
      },
      2019 => {
        annual_poverty_guideline: BigDecimal(12_490.to_s),
        annual_per_person_amount: BigDecimal(4_420.to_s)
      },
      2020 => {
        annual_poverty_guideline: BigDecimal(12_760.to_s),
        annual_per_person_amount: BigDecimal(4_480.to_s)
      },
      2021 => {
        annual_poverty_guideline: BigDecimal(12_880.to_s),
        annual_per_person_amount: BigDecimal(4_540.to_s)
      },
      2022 => {
        annual_poverty_guideline: BigDecimal(13_590.to_s),
        annual_per_person_amount: BigDecimal(4_720.to_s)
      },
      2023 => {
        annual_poverty_guideline: BigDecimal(13_590.to_s),
        annual_per_person_amount: BigDecimal(4_720.to_s)
      }
    }
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
    field_names = %w[primary_person_hbx_id family_hbx_assigned_id aptc_csr_tax_households_count migrated_tax_households_count(new) family_has_active_tax_households?]

    CSV.open(file_name, 'w', force_quotes: true) do |csv|
      csv << field_names

      families.no_timeout.limit(5_000).offset(offset_count).inject([]) do |_dummy, family|
        logger.info "---------- Processing Family with family_hbx_assigned_id: #{family.hbx_assigned_id}"
        unless family.valid?
          logger.info "----- Invalid family with family_hbx_assigned_id: #{family.hbx_assigned_id}, errors: #{family.errors.full_messages}"
          next family
        end

        active_thhs_of_household = family.active_household.tax_households.active_tax_household.tax_household_with_year(2022)
        if active_thhs_of_household.present?
          active_2022_tax_household_groups = family.tax_household_groups.by_year(2022)
          family = if active_2022_tax_household_groups.present?
                     process_inactive_thhs_of_household(family, active_thhs_of_household, true)
                   else
                     process_active_thhs_of_household(family, active_thhs_of_household)
                   end
        end

        inactive_thhs_of_household = family.active_household.tax_households.where(:effective_ending_on.ne => nil).tax_household_with_year(2022)
        family = process_inactive_thhs_of_household(family, inactive_thhs_of_household, false) if inactive_thhs_of_household.present?
        if family.save!
          logger.info "----- Successfully created TaxHouseholdGroups for family with family_hbx_assigned_id: #{family.hbx_assigned_id}"
          determination = ::Operations::Eligibilities::BuildFamilyDetermination.new.call(family: family.reload, effective_date: TimeKeeper.date_of_record)
          if determination.success?
            logger.info "----- Successfully created FamilyDetermination: #{determination.success} for family with family_hbx_assigned_id: #{family.hbx_assigned_id}"
          else
            logger.info "----- Failed to create FamilyDetermination: #{determination.failure} for family with family_hbx_assigned_id: #{family.hbx_assigned_id}"
          end
        else
          logger.info "----- Errors persisting family with family_hbx_assigned_id: #{family.hbx_assigned_id}, errors: #{family.errors.full_messages}"
        end

        csv << [family.primary_person.hbx_id, family.hbx_assigned_id, family.active_household.tax_households.count, family.reload.tax_household_groups.map(&:tax_households).flatten.count, active_thhs_of_household.present?]
      rescue StandardError => e
        logger.info "----- Error raised processing family with family_hbx_assigned_id: #{family.hbx_assigned_id}, error: #{e}, backtrace: #{e.backtrace.join('\n')}"
      end
    end
  end

  def find_families
    hbx_ids = ENV['person_hbx_ids'].to_s.split(',')

    if hbx_ids.present?
      family_hbx_ids = Person.where(:hbx_id.in => hbx_ids).map(&:primary_family).compact.map(&:hbx_assigned_id)
      Family.all_tax_households.where(:hbx_assigned_id.in => family_hbx_ids)
    else
      Family.all_tax_households
    end
  end

  def migrate
    @logger = Logger.new("#{Rails.root}/log/migrate_household_thhs_to_thh_group_thhs_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
    start_time = DateTime.current
    @logger.info "MigrateHouseholdThhsToThhGroupThhs start_time: #{start_time}"
    @app_ambiguity_hbx_ids = []
    families = find_families
    total_count = families.count
    familes_per_iteration = 5_000.0
    number_of_iterations = (total_count / familes_per_iteration).ceil
    counter = 0

    while counter < number_of_iterations
      file_name = "#{Rails.root}/household_thhs_to_thh_group_thhs_migration_list_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}_#{counter + 1}.csv"
      offset_count = familes_per_iteration * counter
      process_families(families, file_name, offset_count, @logger)
      counter += 1
    end
    end_time = DateTime.current
    @logger.info "MigrateHouseholdThhsToThhGroupThhs end_time: #{end_time}, total_time_taken_in_minutes: #{((end_time - start_time) * 24 * 60).to_f.ceil}" unless Rails.env.test?
    @logger.info "Families with missing yearly_expected_contribution - #{@app_ambiguity_hbx_ids}"
  end
end
