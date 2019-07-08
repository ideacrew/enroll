require File.join(Rails.root, "lib/mongoid_migration_task")

class UnsetBgaId < MongoidMigrationTask
  def migrate
    enrollment = HbxEnrollment.by_hbx_id(ENV['hbx_id']).first
    if enrollment.nil?
      puts "Incorrect number of enrollments returned for hbx_id: #{ENV['hbx_id']}" unless Rails.env.test?
    else
      enrollment.unset(:benefit_group_assignment_id)
      puts "Updated benefit group assignment id" unless Rails.env.test?
    end
  end
end
