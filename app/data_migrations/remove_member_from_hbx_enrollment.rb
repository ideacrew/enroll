require File.join(Rails.root, "lib/mongoid_migration_task")

class RemoveMemberFromHbxEnrollment < MongoidMigrationTask
  def migrate
    enrollment_hbx_id = ENV["enrollment_hbx_id"]
    applicant_id = ENV["applicant_id"]
    hbx_enrollment=HbxEnrollment.by_hbx_id(enrollment_hbx_id)
    if hbx_enrollment.blank?
      puts "No hbx_enrollment was found with the given hbx_id"
    else
      enrollment_member=hbx_enrollment[0].hbx_enrollment_members.where(applicant_id:applicant_id).first
      if enrollment_member.nil?
        puts "No enrollment member was found with the given applicant id"
      else
        enrollment_member.destroy
        puts "The enrollment member with applicant_id #{applicant_id} was removed from enrollment #{enrollment_hbx_id}"
      end
    end
  end
end
