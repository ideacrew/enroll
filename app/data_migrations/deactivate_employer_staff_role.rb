require File.join(Rails.root, "lib/mongoid_migration_task")

class DeactivateEmployerStaffRole < MongoidMigrationTask
  def migrate

    organization = Organization.where(:'employer_profile'.exists => true, fein: ENV['fein']).first
    person= Person.by_hbx_id(ENV['hbx_id']).first

    if organization.present? && person.present?
      Person.deactivate_employer_staff_role(person.id, organization.employer_profile.id)
      puts "Deactivated employer staff role" unless Rails.env.test?
    else
      unless Rails.env.test?
        puts "No organization was found by the given fein: #{ENV['fein']}" if organization.blank?
        puts "No person found by the given hbx_id: #{ENV['hbx_id']}" if person.blank?
      end
    end
  end
end
