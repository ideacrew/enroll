
require File.join(Rails.root, "lib/mongoid_migration_task")

class RemoveCensusEmployees < MongoidMigrationTask
  def migrate
    organizations = Organization.where(fein: ENV['fein'])
    if organizations.size !=1
      raise 'Issues with fein'
    end
    organizations.first.employer_profile.census_employees.each(&:destroy)
    puts "Deleted employees for Organization with fein: #{ENV['fein']}" unless Rails.env.test?
  end
end
