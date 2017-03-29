require File.join(Rails.root, "lib/mongoid_migration_task")
class ChangeFein< MongoidMigrationTask
  def migrate
    organization = Organization.where(fein:ENV['old_fein']).first
    new_fein = ENV['new_fein']
    if organization.nil?
      puts "No organization was found by the given fein"
    else
      organization.update_attributes(fein:new_fein)
      puts "Changed fein to #{new_fein}" unless Rails.env.test?
    end
  end
end