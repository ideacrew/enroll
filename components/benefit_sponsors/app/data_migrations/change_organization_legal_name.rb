require File.join(Rails.root, "components/benefit_sponsors/lib/mongoid_migration_task")

class ChangeOrganizationLegalName < MongoidMigrationTask
  def migrate
    fein = ENV['fein']
    new_legal_name = ENV['new_legal_name']
    organizations = ::BenefitSponsors::Organizations::Organization.where(fein:fein)

    if organizations.size == 0
      puts "No organization was found with the given fein: #{fein}" unless Rails.env.test?
      return
    elsif organizations.size > 1
      puts "More than one organization was found with the given fein: #{fein}" unless Rails.env.test?
      return
    end

    organizations.first.update_attributes!(legal_name: new_legal_name)
    puts "organization with #{fein} is updated with the new_legal_name: #{new_legal_name}"  unless Rails.env.test?
  end
end
