
require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateHbxEnrollmentEmployeeRoleId < MongoidMigrationTask
  def migrate
  	employee_role_id = ENV['employee_role_id'].to_s
    enrollment = HbxEnrollment.by_hbx_id(ENV['enrollment_hbx_id'].to_s).first
    if enrollment.present?
		  enrollment.update_attributes!(employee_role_id: employee_role_id)
    	puts "change employee_role_id for enrollment: #{enrollment.id} to #{employee_role_id}" unless Rails.env.test?
    else
      puts "No enrollment found" unless Rails.env.test?
  	end
  end
end
