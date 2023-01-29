# frozen_string_literal: true

require File.join(Rails.root, 'lib/mongoid_migration_task')

# This class is for updating TaxHouseholdEnrollment objects for Health Enrollments that got created on or after 2022/1/1.
#   1. Continuous Coverage
#   2. Children aged 20 or below. This is to fix the incorrectly calculated second lowest cost standalone dental plan ehb premium
# This class will not update Enrollment.
class UpdateBenchmarkForContinuousCoverageAndChildMemberEnrs < MongoidMigrationTask
  def update_not_needed?(household_info, th_enrollment)
    th_enrollment.household_benchmark_ehb_premium.to_d == household_info.household_benchmark_ehb_premium.to_d &&
      th_enrollment.health_product_hios_id == household_info.health_product_hios_id &&
      th_enrollment.dental_product_hios_id == household_info.dental_product_hios_id &&
      th_enrollment.household_health_benchmark_ehb_premium.to_d == household_info.household_health_benchmark_ehb_premium.to_d &&
      th_enrollment.household_dental_benchmark_ehb_premium&.to_d == household_info.household_dental_benchmark_ehb_premium&.to_d
  end

  def update_benchmark_premiums(family, enrollment, enrolled_family_member_ids, old_tax_hh_enrs)
    households_hash = old_tax_hh_enrs.inject([]) do |result, tax_hh_enr|
      members_hash = (tax_hh_enr.tax_household.aptc_members.map(&:applicant_id) & enrolled_family_member_ids).inject([]) do |member_result, member_id|
        family_member = family.family_members.where(id: member_id).first

        member_result << {
          family_member_id: member_id,
          coverage_start_on: enrollment.hbx_enrollment_members.where(applicant_id: member_id).first&.coverage_start_on,
          relationship_with_primary: family_member.primary_relationship
        }

        member_result
      end
      next result if members_hash.blank?

      result << {
        household_id: tax_hh_enr.tax_household_id.to_s,
        members: members_hash
      }
      result
    end

    if households_hash.blank?
      @logger.info "---------- EnrHbxID: #{enrollment.hbx_id} - Unable to construct Benchmark Premiums payload"
      return
    end

    payload = {
      family_id: family.id,
      effective_date: enrollment.effective_on,
      households: households_hash
    }
    benchmark_premiums_result = ::Operations::BenchmarkProducts::IdentifySlcspWithPediatricDentalCosts.new.call(payload)

    if benchmark_premiums_result.failure?
      errors = if benchmark_premiums_result.failure.is_a?(Dry::Validation::Result)
                 result.failure.errors.to_h
               else
                 result.failure
               end
      @logger.info "---------- EnrHbxID: #{enrollment.hbx_id} - BenchmarkPremiums issue errors: #{errors}"

      return
    end

    benchmark_premiums = benchmark_premiums_result.success

    old_tax_hh_enrs.each do |th_enrollment|
      household_info = benchmark_premiums.households.find { |household| household.household_id.to_s == th_enrollment.tax_household_id.to_s }
      next th_enrollment if household_info.nil?

      if update_not_needed?(household_info, th_enrollment)
        @logger.info "---------- EnrHbxID: #{enrollment.hbx_id} - Update not needed as TaxHouseholdEnrollment information is same. TaxHousehold hbx_assigned_id: #{th_enrollment.tax_household.hbx_assigned_id}"
        next th_enrollment
      end
      th_enrollment.update!(
        household_benchmark_ehb_premium: household_info.household_benchmark_ehb_premium,
        health_product_hios_id: household_info.health_product_hios_id,
        dental_product_hios_id: household_info.dental_product_hios_id,
        household_health_benchmark_ehb_premium: household_info.household_health_benchmark_ehb_premium,
        household_dental_benchmark_ehb_premium: household_info.household_dental_benchmark_ehb_premium
      )

      th_enrollment.tax_household_members_enrollment_members.each do |member|
        hh_member = household_info.members.detect { |mmbr| mmbr.family_member_id == member.family_member_id }
        next member if hh_member.blank?

        member.update!(age_on_effective_date: hh_member.age_on_effective_date)
      end
    end
    true
  end

  def process_enrollment(enrollment)
    old_tax_hh_enrs = TaxHouseholdEnrollment.where(enrollment_id: enrollment.id)
    if old_tax_hh_enrs.blank?
      @logger.info "---------- EnrHbxID: #{enrollment.hbx_id} - No TaxHouseholdEnrollments for Enrollment"
      return
    end

    old_household_benchmark_ehb_premiums = old_tax_hh_enrs.pluck(:household_benchmark_ehb_premium)
    old_health_product_hios_ids = old_tax_hh_enrs.pluck(:health_product_hios_id)
    old_dental_product_hios_ids = old_tax_hh_enrs.pluck(:dental_product_hios_id)
    old_household_health_benchmark_ehb_premiums = old_tax_hh_enrs.pluck(:household_health_benchmark_ehb_premium)
    old_household_dental_benchmark_ehb_premiums = old_tax_hh_enrs.pluck(:household_dental_benchmark_ehb_premium)
    old_applied_aptcs = old_tax_hh_enrs.pluck(:applied_aptc)
    old_available_max_aptcs = old_tax_hh_enrs.pluck(:available_max_aptc)
    enrollment_members_info = enrollment.hbx_enrollment_members.inject({}) do |haash, enr_member|
      haash[enr_member.person.full_name] = enr_member.coverage_start_on.to_s
      haash
    end
    family = enrollment.family
    enrolled_family_member_ids = enrollment.hbx_enrollment_members.map(&:applicant_id)
    updated = update_benchmark_premiums(family, enrollment, enrolled_family_member_ids, old_tax_hh_enrs)
    return unless updated

    new_tax_hh_enrs = TaxHouseholdEnrollment.where(enrollment_id: enrollment.id)
    [
      family.primary_person.hbx_id,
      enrollment.hbx_id,
      enrollment.aasm_state,
      enrollment.total_premium.to_f,
      enrollment.effective_on,
      enrollment.product.ehb,
      enrollment.applied_aptc_amount.to_f,
      enrollment_members_info,
      old_household_benchmark_ehb_premiums,
      old_health_product_hios_ids,
      old_dental_product_hios_ids,
      old_household_health_benchmark_ehb_premiums,
      old_household_dental_benchmark_ehb_premiums,
      old_applied_aptcs,
      old_available_max_aptcs,
      new_tax_hh_enrs.pluck(:household_benchmark_ehb_premium),
      new_tax_hh_enrs.pluck(:health_product_hios_id),
      new_tax_hh_enrs.pluck(:dental_product_hios_id),
      new_tax_hh_enrs.pluck(:household_health_benchmark_ehb_premium),
      new_tax_hh_enrs.pluck(:household_dental_benchmark_ehb_premium),
      new_tax_hh_enrs.pluck(:applied_aptc),
      new_tax_hh_enrs.pluck(:available_max_aptc)
    ]
  end

  def find_enrollment_hbx_ids
    hbx_ids = ENV['enrollment_hbx_ids'].to_s.split(',').map(&:squish!)
    return hbx_ids if hbx_ids.present?

    HbxEnrollment.where(
      coverage_kind: 'health',
      :consumer_role_id.ne => nil,
      :product_id.ne => nil,
      :aasm_state.ne => ['shopping', 'coverage_canceled'],
      :effective_on.gte => Date.new(2022),
      :'applied_aptc_amount.cents'.gt => 0
    ).pluck(:hbx_id)
  end

  # Dental Benchmark fix for enrollments that got created before Slcsapd fix(https://github.com/ideacrew/enroll/pull/2254)
  def any_child_aged_20_or_below?(enrollment)
    enrollment.hbx_enrollment_members.any?{ |member| member.age_on_effective_date <= 20 && member.primary_relationship == 'child' }
  end

  def continuous_coverage_enr?(enrollment)
    enrollment.hbx_enrollment_members.any?{ |member| member.coverage_start_on != enrollment.effective_on }
  end

  def process_hbx_enrollment_hbx_ids
    file_name = "#{Rails.root}/benchmark_for_continuous_coverage_enrollments_list_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.csv"
    counter = 0

    field_names = %w[person_hbx_id enrollment_hbx_id enrollment_aasm_state enrollment_total_premium enrollment_effective_on
                     product_ehb enrollment_applied_aptc_amount enrollment_members_with_coverage_start_on
                     old_household_benchmark_ehb_premiums old_health_product_hios_ids old_dental_product_hios_ids old_household_health_benchmark_ehb_premiums
                     old_household_dental_benchmark_ehb_premiums old_applied_aptcs old_available_max_aptcs
                     new_household_benchmark_ehb_premiums new_health_product_hios_ids new_dental_product_hios_ids new_household_health_benchmark_ehb_premiums
                     new_household_dental_benchmark_ehb_premiums new_applied_aptcs new_available_max_aptcs]

    CSV.open(file_name, 'w', force_quotes: true) do |csv|
      csv << field_names
      find_enrollment_hbx_ids.each do |hbx_id|
        counter += 1
        @logger.info "Processed #{counter} hbx_enrollments" if counter % 100 == 0
        @logger.info "----- EnrHbxID: #{hbx_id} - Processing Enrollment"
        enrollment = HbxEnrollment.by_hbx_id(hbx_id).first
        if enrollment.blank?
          @logger.info "---------- EnrHbxID: #{enrollment.hbx_id} - Enrollment not found"
          next hbx_id
        end
        next hbx_id unless any_child_aged_20_or_below?(enrollment) || continuous_coverage_enr?(enrollment)

        csv_result = process_enrollment(enrollment)
        next hbx_id if csv_result.nil?

        csv << csv_result
        @logger.info "---------- EnrHbxID: #{hbx_id} - Finished processing Enrollment"
      rescue StandardError => e
        @logger.info "---------- EnrHbxID: #{hbx_id} - Error raised processing enrollment, error: #{e}, backtrace: #{e.backtrace}"
      end
    end
  end

  def migrate
    @logger = Logger.new("#{Rails.root}/log/fix_benchmark_for_continuous_coverage_enrollments_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
    start_time = DateTime.current
    @logger.info "UpdateBenchmarkForContinuousCoverageAndChildMemberEnrs start_time: #{start_time}"
    process_hbx_enrollment_hbx_ids
    end_time = DateTime.current
    @logger.info "UpdateBenchmarkForContinuousCoverageAndChildMemberEnrs end_time: #{end_time}, total_time_taken_in_minutes: #{((end_time - start_time) * 24 * 60).to_f.ceil}"
  end
end
