require File.join(Rails.root, "lib/mongoid_migration_task")

class ChangeOrganizationLegalName < MongoidMigrationTask
  def migrate
    fein = ENV['fein']
    new_legal_name = ENV['new_legal_name']
    organization = Organization.where(fein:fein)
    if organization.size == 0
      puts "No organization was found with the given fein" unless Rails.env.test?
      return
    elsif organization.size > 1
      puts "More than one organization was found with the given fein" unless Rails.env.test?
      return
    end
    organization.first.update_attributes(legal_name:new_legal_name)
    puts "organization with #{fein} has new legal name #{new_legal_name}"  unless Rails.env.test?
  end
end
