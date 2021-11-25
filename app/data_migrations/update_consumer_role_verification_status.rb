# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")
# update consumer_role aasm state to fully verified if required validationn statuses are verified
class UpdateConsumerRoleVerificationStatus < MongoidMigrationTask
  def migrate
    HbxEnrollment.individual_market.enrolled_and_renewing.by_unverified.no_timeout.each do |hbx_enrollment|
      consumer_roles = hbx_enrollment.hbx_enrollment_members.flat_map(&:person).flat_map(&:consumer_role)

      consumer_roles.each do |role|
        update_consumer_role(role)
      end

      if consumer_roles.map(&:aasm_state).all?("fully_verified")
        hbx_enrollment.update!(is_any_enrollment_member_outstanding: false)
        puts "updated for person #{hbx_enrollment.family.primary_person.hbx_id}"
      end
    rescue StandardError => e
      puts "failed for person #{hbx_enrollment&.family&.primary_person&.hbx_id} due to #{e.inspect} "
    end
  end

  def update_consumer_role(role)
    role.update!(aasm_state: "fully_verified") if role.verification_types.map(&:validation_status).all?("verified") && role.aasm_state.to_s != "fully_verified"
  end
end
