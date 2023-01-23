# frozen_string_literal: true

require File.join(Rails.root, 'lib/mongoid_migration_task')
require File.join(Rails.root, 'app/helpers/float_helper')

# Rake task is to populate applied_aptc for TaxHouseholdEnrollment objects for Health Enrollments with effective on or after 2022/1/1.
# This class will not update Enrollment.
class PopulateAppliedAptcForThhEnrs < MongoidMigrationTask
  include ::FloatHelper

  def find_enrollment_hbx_ids
    hbx_ids = ENV['enrollment_hbx_ids'].to_s.split(',').map(&:squish!)
    return hbx_ids if hbx_ids.present?

    HbxEnrollment.where(
      :effective_on.gte => Date.new(2022),
      :aasm_state.ne => ['shopping', 'coverage_canceled'],
      :product_id.ne => nil,
      coverage_kind: 'health',
      :consumer_role_id.ne => nil
    ).pluck(:hbx_id)
  end

  def sum_of_member_ehb_premiums(enrollment, thh_enr)
    aptc_family_member_ids = thh_enr.tax_household.aptc_members.map(&:applicant_id)
    enrollment.hbx_enrollment_members.where(:applicant_id.in => aptc_family_member_ids).reduce(0) do |sum, member|
      sum + enrollment.ivl_decorated_hbx_enrollment.member_ehb_premium(member)
    end
  end

  def update_single_thh_enr(enrollment, thh_enr)
    thh_enr.update_attributes!(
      {
        applied_aptc: enrollment.applied_aptc_amount,
        group_ehb_premium: float_fix(sum_of_member_ehb_premiums(enrollment, thh_enr))
      }
    )
  end

  def populate_info_to_csv(family, enrollment, thh_enr)
    thh = thh_enr.tax_household
    [
      family.primary_person.hbx_id,
      enrollment.hbx_id,
      enrollment.aasm_state,
      enrollment.total_premium.to_f,
      enrollment.effective_on,
      enrollment.product.ehb,
      enrollment.applied_aptc_amount.to_f,
      thh_enr.applied_aptc.to_f,
      thh_enr.group_ehb_premium.to_f,
      thh.monthly_expected_contribution.to_f,
      thh.hbx_assigned_id,
      thh_enr.household_benchmark_ehb_premium.to_f,
      thh_enr.health_product_hios_id,
      thh_enr.dental_product_hios_id,
      thh_enr.household_health_benchmark_ehb_premium.to_f,
      thh_enr.household_dental_benchmark_ehb_premium.to_f,
      thh_enr.available_max_aptc.to_f
    ]
  end

  def find_premiums_for_thh_enrs(enrollment, tax_hh_enrs)
    ratio = enrollment.applied_aptc_amount / tax_hh_enrs.map(&:available_max_aptc).sum

    tax_hh_enrs.inject({}) do |thh_enr_premiums_hash, thh_enrollment|
      assumed_applied_aptc = ratio * (thh_enrollment.available_max_aptc.positive? ? thh_enrollment.available_max_aptc : 0.00.to_money)
      group_ehb_cost = Money.new(
        float_fix(sum_of_member_ehb_premiums(enrollment, thh_enrollment)) * 100
      )

      assumed_applied_aptc_greater_than_group_ehb_premium = assumed_applied_aptc > group_ehb_cost
      thh_enr_premiums_hash[thh_enrollment] = {
        assumed_applied_aptc: assumed_applied_aptc,
        group_ehb_premium: group_ehb_cost,
        available_max_aptc: thh_enrollment.available_max_aptc.positive? ? thh_enrollment.available_max_aptc : 0.00.to_money,
        assumed_applied_aptc_greater_than_group_ehb_premium: assumed_applied_aptc_greater_than_group_ehb_premium,
        applied_aptc: assumed_applied_aptc_greater_than_group_ehb_premium ? group_ehb_cost : nil
      }

      thh_enr_premiums_hash
    end
  end

  def find_non_applied_aptc_thh_enrs(thh_enr_premiums)
    thh_enr_premiums.select do |_thh_enr, premium_hash|
      premium_hash[:applied_aptc].nil?
    end
  end

  def set_applied_aptc_for_remaining_thh_enrs(thh_enr_premiums, non_applied_aptc_thh_enrs, applied_aptc_amount)
    non_applied_aptc_count = non_applied_aptc_thh_enrs.count
    remaining_consumed_aptc = applied_aptc_amount - thh_enr_premiums.values.collect { |val| val[:applied_aptc].presence || 0.00 }.sum
    ratio = remaining_consumed_aptc / non_applied_aptc_thh_enrs.values.reduce(0) {|sum, thh_enr_hash|  sum + thh_enr_hash[:available_max_aptc] }

    non_applied_aptc_thh_enrs.each_with_index do |haash, i|
      thh_enr = haash.first
      thh_enr_premiums[thh_enr][:applied_aptc] =
        if i == non_applied_aptc_count.pred
          applied_aptc_amount - thh_enr_premiums.values.collect { |val| val[:applied_aptc].presence || 0.00 }.sum
        else
          ratio * thh_enr_premiums[thh_enr][:available_max_aptc]
        end
    end

    thh_enr_premiums
  end

  def update_thh_enrs_ineligible_for_applied_aptc(tax_hh_enrs)
    tax_hh_enrs.each do |thh_enr|
      thh_enr.applied_aptc = 0.00
      thh_enr.group_ehb_premium = 0.00
      thh_enr.save!
    end
  end

  def update_multiple_thh_enrs(_family, enrollment, tax_hh_enrs)
    thh_enr_premiums = find_premiums_for_thh_enrs(enrollment, tax_hh_enrs)
    non_applied_aptc_thh_enrs = find_non_applied_aptc_thh_enrs(thh_enr_premiums)
    applied_aptc_amount = enrollment.applied_aptc_amount

    thh_enr_premiums =
      if non_applied_aptc_thh_enrs.count == 1
        thh_enr_premiums[non_applied_aptc_thh_enrs.keys.first][:applied_aptc] =
          applied_aptc_amount - thh_enr_premiums.values.collect { |val| val[:applied_aptc].presence || 0.00  }.sum

        thh_enr_premiums
      else
        set_applied_aptc_for_remaining_thh_enrs(thh_enr_premiums, non_applied_aptc_thh_enrs, applied_aptc_amount)
      end

    thh_enr_premiums.each do |thh_enr, premiums_hash|
      thh_enr.applied_aptc = premiums_hash[:applied_aptc]
      thh_enr.group_ehb_premium = premiums_hash[:group_ehb_premium]
      thh_enr.save!
    end
  end

  def update_applied_aptc_for_thh_enrs_with_negative_available_aptc(enrollment)
    TaxHouseholdEnrollment.where(enrollment_id: enrollment.id, :'available_max_aptc.cents'.lte => 0.00).each do |thh_enr|
      thh_enr.update_attributes!(
        applied_aptc: 0.00,
        group_ehb_premium: 0.00
      )
    end
  end

  def aptc_tax_household_enrollments(enrollment)
    TaxHouseholdEnrollment.where(enrollment_id: enrollment.id).select do |thh_enr|
      thh_enr.available_max_aptc.positive? && thh_enr.tax_household_members_enrollment_members.where(
        :family_member_id.in => thh_enr.tax_household.aptc_members.map(&:applicant_id)
      ).present?
    end
  end

  def eligible_to_populate_applied_aptc?(enrollment)
    enrollment.effective_on >= Date.new(2022) &&
      ['shopping', 'coverage_canceled'].exclude?(enrollment.aasm_state) &&
      enrollment.product_id.present? &&
      enrollment.coverage_kind == 'health' &&
      enrollment.applied_aptc_amount.positive? &&
      enrollment.consumer_role_id.present?
  end

  def process_hbx_enrollment_hbx_ids
    file_name = "#{Rails.root}/populate_applied_aptc_for_thh_enrs_list_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.csv"
    counter = 0

    field_names = %w[person_hbx_id enrollment_hbx_id enrollment_aasm_state enrollment_total_premium enrollment_effective_on
                     product_ehb enrollment_applied_aptc_amount thh_enr_applied_aptc group_ehb_premium thh_monthly_expected_contribution
                     thh_hbx_assigned_id household_benchmark_ehb_premium health_product_hios_id dental_product_hios_id
                     household_health_benchmark_ehb_premium household_dental_benchmark_ehb_premium available_max_aptc]

    CSV.open(file_name, 'w', force_quotes: true) do |csv|
      csv << field_names
      find_enrollment_hbx_ids.each do |hbx_id|
        counter += 1
        @logger.info "Processed #{counter} hbx_enrollments" if counter % 100 == 0
        @logger.info "----- EnrHbxID: #{hbx_id} - Processing Enrollment"
        enrollment = HbxEnrollment.by_hbx_id(hbx_id).first
        family = enrollment.family
        update_applied_aptc_for_thh_enrs_with_negative_available_aptc(enrollment)
        tax_hh_enrs = aptc_tax_household_enrollments(enrollment)
        if tax_hh_enrs.blank?
          @logger.info "---------- EnrHbxID: #{hbx_id} - No TaxHouseholdEnrollments for Enrollment"
          next hbx_id
        end

        if !eligible_to_populate_applied_aptc?(enrollment)
          update_thh_enrs_ineligible_for_applied_aptc(tax_hh_enrs)
        elsif tax_hh_enrs.count == 1
          update_single_thh_enr(enrollment, tax_hh_enrs.first)
        else
          update_multiple_thh_enrs(family, enrollment, tax_hh_enrs)
        end

        TaxHouseholdEnrollment.where(enrollment_id: enrollment.id).each do |thh_enr|
          csv << populate_info_to_csv(family, enrollment, thh_enr)
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
