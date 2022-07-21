# frozen_string_literal: true

require File.join(Rails.root, 'lib/mongoid_migration_task')

# This class is for migrating TaxHousehold, TaxhouseholdMember, and EligibilityDetermination to GroupPremiumCredit, and MemberPremiumCredit
class MigrateThhsToPremiumCredits < MongoidMigrationTask
  def group_premium_credit(thh)
    {
      kind: 'aptc_csr',
      premium_credit_monthly_cap: thh.current_max_aptc.to_f,
      sub_group_id: thh.id.to_s,
      sub_group_class: thh.class.to_s,
      start_on: thh.effective_starting_on,
      end_on: thh.effective_ending_on,
      member_premium_credits: member_premium_credits(thh)
    }
  end

  def member_premium_credits(thh)
    thh.aptc_members.inject([]) do |members, aptc_csr_member|
      members << {
        kind: 'aptc_eligible',
        value: 'true',
        start_on: thh.effective_starting_on,
        end_on: thh.effective_ending_on,
        family_member_id: aptc_csr_member.applicant_id
      }

      members << {
        kind: 'csr',
        value: aptc_csr_member.csr_eligibility_kind.delete('csr_'),
        start_on: thh.effective_starting_on,
        end_on: thh.effective_ending_on,
        family_member_id: aptc_csr_member.applicant_id
      }
    end
  end

  def failure_message(result)
    failure = result.failure
    case failure
    when Dry::Validation::Result
      failure.errors.to_h
    else
      failure
    end
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
        aptc_csr_thhs = family.active_household.tax_households.where(:'tax_household_members.is_ia_eligible' => true)

        aptc_csr_thhs.each do |thh|
          result = ::Operations::PremiumCredits::Build.new.call({ family: family, gpc_params: group_premium_credit(thh) })
          if result.success?
            family = result.success
          else
            logger.info "----- Unable to build GroupPremiumCredit for thh_id: #{thh.id}, failure: #{failure_message(result)}"
            next family
          end
        end

        if family.save
          logger.info "----- Successfully created PremiumCredits for family with family_hbx_assigned_id: #{family.hbx_assigned_id}"
        else
          logger.info "----- Errors persisting family with family_hbx_assigned_id: #{family.hbx_assigned_id}, errors: #{family.errors.full_messages}"
        end
        csv << [family.primary_person.hbx_id, family.hbx_assigned_id, aptc_csr_thhs.count, family.reload.group_premium_credits.count]
      rescue StandardError => e
        logger.info "----- Error raised processing family with family_hbx_assigned_id: #{family.hbx_assigned_id}, error: #{e}, backtrace: #{e.backtrace.join('\n')}"
      end
    end
  end

  def migrate
    logger = Logger.new("#{Rails.root}/log/migrate_thhs_to_premium_credits_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
    start_time = DateTime.current
    logger.info "MigrateThhsToPremiumCredits start_time: #{start_time}"
    families = Family.all_tax_households
    total_count = families.count
    familes_per_iteration = 5_000.0
    number_of_iterations = (total_count / familes_per_iteration).ceil
    counter = 0

    while counter < number_of_iterations
      file_name = "#{Rails.root}/thhs_to_premim_credits_migration_list_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}_#{counter + 1}.csv"
      offset_count = familes_per_iteration * counter
      process_families(families, file_name, offset_count, logger)
      counter += 1
    end
    end_time = DateTime.current
    logger.info "MigrateThhsToPremiumCredits end_time: #{end_time}, total_time_taken_in_minutes: #{((end_time - start_time) * 24 * 60).to_f.ceil}" unless Rails.env.test?
  end
end
