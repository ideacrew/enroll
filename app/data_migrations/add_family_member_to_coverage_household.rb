require File.join(Rails.root, "lib/mongoid_migration_task")

class AddFamilyMemberToCoverageHousehold < MongoidMigrationTask
  def migrate
    person = Person.where(hbx_id: ENV['hbx_id']).first
    family = person.primary_family
    family_member = person.primary_family.primary_applicant
    family.active_household.add_household_coverage_member(family_member)
    family.save
  end
end