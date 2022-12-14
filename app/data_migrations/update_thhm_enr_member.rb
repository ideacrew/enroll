# frozen_string_literal: true

require File.join(Rails.root, 'lib/mongoid_migration_task')

# Updates TaxHouseholdMemberEnrollmentMember objects for HbxEnrollments that got created on or after 2022/10/1
# Given that TaxHouseholdMember ids are correct.
class UpdateThhmEnrMember < MongoidMigrationTask
  def process_enrollments(enrollment_hbx_ids, logger)
    enrollment_hbx_ids.inject([]) do |_dummy, enr_hbx_id|
      enrollment = HbxEnrollment.where(hbx_id: enr_hbx_id).first
      tax_household_enrollments = TaxHouseholdEnrollment.where(enrollment_id: enrollment.id)

      tax_household_enrollments.each do |thh_enr|
        thh = thh_enr.tax_household
        enr_member_ids = enrollment.hbx_enrollment_members.pluck(:id)
        bad_thh_member_enr_members = thh_enr.tax_household_members_enrollment_members.select do |thh_member_enr_member|
          enr_member_ids.exclude?(thh_member_enr_member.hbx_enrollment_member_id)
        end

        next unless bad_thh_member_enr_members.present?
        assign_enr_member_id(bad_thh_member_enr_members, enrollment, thh, thh_enr)
        thh_enr.save!
      end
      logger.info "Successfully processed enrollment with hbx_id: #{enrollment.hbx_id}" unless Rails.env.test?
    rescue StandardError => e
      logger.info "Error: Message: #{e}, Backtrace: #{e.backtrace.join('\n')}, enrollment_hbx_id: #{enrollment.hbx_id}" unless Rails.env.test?
    end
  end

  def assign_enr_member_id(bad_thh_member_enr_members, enrollment, thh, thh_enr)
    bad_thh_member_enr_members.each do |bad_thh_member_enr_mmbr|
      applicant_id = bad_thh_member_enr_mmbr.family_member_id
      if applicant_id.present?
        enr_mmbr = enrollment.hbx_enrollment_members.where(applicant_id: applicant_id).first
        family_member = enrollment.family.family_members.where(id: applicant_id).first
        if enr_mmbr.present?
          bad_thh_member_enr_mmbr.hbx_enrollment_member_id = enr_mmbr.id
        else
          logger.info "No Matching HbxEnrollmentMember on enrollment with hbx_id: #{enrollment.hbx_id}, person_hbx_id: #{family_member.hbx_id}" unless Rails.env.test?
        end
      else
        logger.info "No Matching TaxHouseholdMember for FamilyMemberId: #{family_member_id} on thh with hbx_assigned_id: #{thh.hbx_assigned_id}" unless Rails.env.test?
      end
    rescue StandardError => e
      logger.info "Error: Message: #{e}, Backtrace: #{e.backtrace.join('\n')}, thh_enr id: #{thh_enr.id}" unless Rails.env.test?
    end
  end

  def fetch_hbx_enrollment_hbx_ids
    ENV['enrollment_hbx_ids'].to_s.split(',').map(&:squish!).presence || HbxEnrollment.where(:created_at.gte => Date.new(2022, 10, 1), coverage_kind: 'health', :aasm_state.ne => 'shopping', :product_id.ne => nil).pluck(:hbx_id)
  end

  def migrate
    logger = Logger.new("#{Rails.root}/log/thhm_enr_member_update_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
    start_time = DateTime.current
    logger.info "UpdateThhmEnrMember start_time: #{start_time}" unless Rails.env.test?
    enrollment_hbx_ids = fetch_hbx_enrollment_hbx_ids
    total_count = enrollment_hbx_ids.count
    logger.info "Total number of enrollments to be processed #{total_count}" unless Rails.env.test?
    process_enrollments(enrollment_hbx_ids, logger)
    end_time = DateTime.current

    logger.info "UpdateThhmEnrMember end_time: #{end_time}, total_time_taken_in_minutes: #{((end_time - start_time) * 24 * 60).to_i}" unless Rails.env.test?
  end
end
