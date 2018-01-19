require File.join(Rails.root, "lib/mongoid_migration_task")

class RemoveInvalidCoverageHouseholdMembers < MongoidMigrationTask
  def migrate
    begin
      person = Person.where(hbx_id: ENV['person_hbx_id'])
      family = person.first.primary_family if person.present?
      if family.present?
        coverage_household = family.active_household.immediate_family_coverage_household
        coverage_household.coverage_household_members.not_in(:family_member_id => family.family_members.map(&:id)).destroy_all
        coverage_household.save
      end
    rescue Exception => e
      puts e.message
    end
  end
end