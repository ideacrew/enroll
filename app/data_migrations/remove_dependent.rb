# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")
class RemoveDependent < MongoidMigrationTask
  def migrate
    begin
      id = BSON::ObjectId.from_string(ENV["family_member_id"].to_s)
      family = Family.where("family_members._id" => id).first
      if family.nil?
        puts "No family member found" unless Rails.env.test?
        return
      end
      family_member = family.family_members.find(id.to_s)
      duplicate_fms_count = family.family_members.where(person_id: family_member.person.id).count
      chm_fm_ids = family.active_household.coverage_households.flat_map(&:coverage_household_members).map(&:family_member_id)
      hbx_member_fm_ids = family.active_household.hbx_enrollments.flat_map(&:hbx_enrollment_members).map(&:applicant_id)
      th_member_ids = family.active_household.tax_households.flat_map(&:tax_household_members).map(&:applicant_id)

      if duplicate_fms_count > 1 && !chm_fm_ids.include?(id) && !hbx_member_fm_ids.include?(id) && !th_member_ids.include?(id)
        family_member.delete
        puts "Removed duplicate family member id: #{id}" unless Rails.env.test?
      else
        puts "Cannot destroy/delete the FamilyMember, reason: This FamilyMember has a CoverageHouseholdMember/HbxEnrollmentMember/TaxHouseholdMember" unless Rails.env.test?
      end
    rescue StandardError => e
      puts e.message unless Rails.env.test?
    end
  end
end
