
require File.join(Rails.root, "lib/mongoid_migration_task")

class RemoveInvalidBenefitGroupAssignmentsForEmployer < MongoidMigrationTask
  def migrate
    organizations = Organization.where(fein: ENV['fein'])
    if organizations.size !=1
      raise 'Issues with the given fein'
    end
    if organizations.first.employer_profile.present?
      organizations.first.employer_profile.census_employees.each do |ce|
        ce.benefit_group_assignments.select { |bga| bga.hbx_enrollments.blank? && bga.benefit_group.blank? }.each do |bga|
          bga.delete
          puts "Deleting invalid benefit group assignments for #{ce.first_name} #{ce.last_name} " unless Rails.env.test?
        end
      end
    end
  end
end
