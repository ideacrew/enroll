
require File.join(Rails.root, "lib/mongoid_migration_task")

class ChangeEnrollmentTerminationDate < MongoidMigrationTask
  def migrate
    enrollment = HbxEnrollment.by_hbx_id(ENV['hbx_id'].to_s)
    new_termination_date = Date.strptime(ENV['new_termination_date'].to_s, "%m/%d/%Y")
    enrollment.first.update_attribute(:terminated_on,new_termination_date)
    puts "Changed Enrollment termination date to #{new_termination_date}" unless Rails.env.test?
  end
end
