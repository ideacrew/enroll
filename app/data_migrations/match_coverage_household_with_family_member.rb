require File.join(Rails.root, "lib/mongoid_migration_task")

class MatchCoverageHouseholdWithFamilyMember < MongoidMigrationTask
  def migrate
    people = Person.where(hbx_id: ENV['hbx_id'])
    raise "More/No people found with the given hbx_id: #{ENV['hbx_id']}" if people.count != 1
    begin
      family = people.first.primary_family
      family.family_members.each { |family_member| 
        family.active_household.add_household_coverage_member(family_member)
        family.active_household.save!}

      # TO delete unwanted(inactive family_members) CHHM records
      active_family_member_ids = family.active_family_members.map(&:id)
      family.active_household.coverage_households.each do |ch|
        ch.coverage_household_members.each { |chm| chm.destroy! unless active_family_member_ids.include?(chm.family_member_id) }
      end
      puts "Successfully updated the family" unless Rails.env.test?
    rescue => e
      puts "Error message: #{e.backtrace}"
    end
  end
end
