# frozen_string_literal: true

require File.join(Rails.root, 'lib/mongoid_migration_task')

# Rake task is to populate applied_aptc for TaxHouseholdEnrollment objects for Health Enrollments with effective on or after 2022/1/1.
# This class will not update Enrollment.
class PopulateAppliedAptcForThhEnrs < MongoidMigrationTask
  def find_enrollment_hbx_ids
    hbx_ids = ENV['enrollment_hbx_ids'].to_s.split(',').map(&:squish!)
    return hbx_ids if hbx_ids.present?

    HbxEnrollment.where(
      :effective_on.gte => Date.new(2022),
      :aasm_state.ne => ['shopping', 'coverage_canceled'],
      :product_id.ne => nil,
      coverage_kind: 'health',
      :'applied_aptc_amount.cents'.gt => 0,
      :consumer_role_id.ne => nil
    ).pluck(:hbx_id)
  end

  def any_negative_applied_aptc?(thh_enr_premiums)
    thh_enr_premiums.any? do |_thh_enr, premiums|
      premiums[:applied_aptc].negative?
    end
  end

  def process_invalid_premiums(thh_enr_premiums, csv, family, enrollment)
    thh_enr_premiums.each do |thh_enr, premiums|
      csv << [
        family.primary_person.hbx_id,
        enrollment.hbx_id,
        enrollment.aasm_state,
        enrollment.total_premium.to_f,
        enrollment.effective_on,
        enrollment.product.ehb,
        enrollment.applied_aptc_amount.to_f,
        premiums[:applied_aptc].to_f,
        thh_enr.household_benchmark_ehb_premium.to_f,
        thh_enr.health_product_hios_id,
        thh_enr.dental_product_hios_id,
        thh_enr.household_health_benchmark_ehb_premium.to_f,
        thh_enr.household_dental_benchmark_ehb_premium.to_f,
        thh_enr.available_max_aptc.to_f,
        premiums[:group_ehb_premium].to_f,
        'No - Negative Applied APTC'
      ]
    end

    csv
  end

  def process_valid_premiums(thh_enr_premiums, csv, family, enrollment)
    thh_enr_premiums.each do |thh_enr, premiums|
      thh_enr.applied_aptc = premiums[:applied_aptc]
      thh_enr.group_ehb_premium = premiums[:group_ehb_premium] if premiums[:group_ehb_premium].present?
      thh_enr.save!

      csv << [
        family.primary_person.hbx_id,
        enrollment.hbx_id,
        enrollment.aasm_state,
        enrollment.total_premium.to_f,
        enrollment.effective_on,
        enrollment.product.ehb,
        enrollment.applied_aptc_amount.to_f,
        thh_enr.applied_aptc.to_f,
        thh_enr.household_benchmark_ehb_premium.to_f,
        thh_enr.health_product_hios_id,
        thh_enr.dental_product_hios_id,
        thh_enr.household_health_benchmark_ehb_premium.to_f,
        thh_enr.household_dental_benchmark_ehb_premium.to_f,
        thh_enr.available_max_aptc.to_f,
        thh_enr.group_ehb_premium.to_f,
        'Yes - Positive/Zero Applied APTC'
      ]
    end

    csv
  end

  def process_hbx_enrollment_hbx_ids
    file_name = "#{Rails.root}/populate_applied_aptc_for_thh_enrs_list_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.csv"
    counter = 0

    field_names = %w[person_hbx_id enrollment_hbx_id enrollment_aasm_state enrollment_total_premium enrollment_effective_on
                     product_ehb enrollment_applied_aptc_amount thh_enr_applied_aptc household_benchmark_ehb_premium
                     health_product_hios_id dental_product_hios_id household_health_benchmark_ehb_premium
                     household_dental_benchmark_ehb_premium available_max_aptc group_ehb_premium TaxHouseholdEnrollmentUpdated?]

    CSV.open(file_name, 'w', force_quotes: true) do |csv|
      csv << field_names
      find_enrollment_hbx_ids.each do |hbx_id|
        counter += 1
        @logger.info "Processed #{counter} hbx_enrollments" if counter % 100 == 0
        @logger.info "----- EnrHbxID: #{hbx_id} - Processing Enrollment"
        enrollment = HbxEnrollment.by_hbx_id(hbx_id).first
        tax_hh_enrs = TaxHouseholdEnrollment.where(enrollment_id: enrollment.id)

        if tax_hh_enrs.blank?
          @logger.info "---------- EnrHbxID: #{hbx_id} - No TaxHouseholdEnrollments for Enrollment"
          next hbx_id
        end

        thh_enr_premiums = enrollment.fetch_thh_enr_premiums
        family = enrollment.family

        csv =
          if any_negative_applied_aptc?(thh_enr_premiums)
            @logger.info "---------- EnrHbxID: #{hbx_id} - Negative AppliedAPTCs for Enrollment"
            process_invalid_premiums(thh_enr_premiums, csv, family, enrollment)
          else
            @logger.info "---------- EnrHbxID: #{hbx_id} - Positive/Zero AppliedAPTCs for Enrollment"
            process_valid_premiums(thh_enr_premiums, csv, family, enrollment)
          end
      rescue StandardError => e
        @logger.info "---------- EnrHbxID: #{hbx_id} - Error raised processing enrollment, error: #{e}, backtrace: #{e.backtrace}"
      end
    end
  end

  def migrate
    @logger = Logger.new("#{Rails.root}/populate_applied_aptc_for_thh_enrs_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
    start_time = DateTime.current
    @logger.info "PopulateAppliedAptcForThhEnrs start_time: #{start_time}"
    process_hbx_enrollment_hbx_ids
    end_time = DateTime.current
    @logger.info "PopulateAppliedAptcForThhEnrs end_time: #{end_time}, total_time_taken_in_minutes: #{((end_time - start_time) * 24 * 60).to_f.ceil}"
  end
end
