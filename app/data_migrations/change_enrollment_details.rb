
require File.join(Rails.root, "lib/mongoid_migration_task")

class ChangeEnrollmentDetails < MongoidMigrationTask
  def migrate
    enrollments = get_enrollment
    action = ENV['action'].to_s

    case action
      when "revert_enrollment"
        revert_enrollment(enrollments)
      when "expire_enrollment"
        expire_enrollment(enrollments)
    end
  end

  def get_enrollment
    hbx_ids = "#{ENV['hbx_id']}".split(',').uniq
    hbx_ids.inject([]) do |enrollments, hbx_id|
      if HbxEnrollment.by_hbx_id(hbx_id.to_s).size != 1
        raise "Found no (OR) more than 1 enrollments with the #{hbx_id}" unless Rails.env.test?
      end
      enrollments << HbxEnrollment.by_hbx_id(hbx_id.to_s).first
    end
  end

  def revert_enrollment(enrollments)
    enrollments.each do |enrollment|
      enrollment.update_attributes(aasm_state: "coverage_enrolled")
      puts "Moved enrollment to Enrolled status from canceled state" unless Rails.env.test?
    end
  end

  def expire_enrollment(enrollments)
    enrollments.each do |enrollment|
      if enrollment.may_expire_coverage?
        enrollment.expire_coverage!
        puts "expire enrollment with hbx_id: #{enrollment.hbx_id}" unless Rails.env.test?
      else
        puts "HbxEnrollment with hbx_id: #{enrollment.hbx_id} can not be expired" unless Rails.env.test?
      end
    end
  end
end
