require File.join(Rails.root, "lib/mongoid_migration_task")
class AddIvlUserDependent < MongoidMigrationTask
   def migrate
   	family = Person.where(first_name: ENV['first_name'], last_name: ENV['last_name'], dob: ENV['dob']).first
   	family= family.families.first
    family_member = family.family_members.where(is_active: "true").detect { |a| a.relationship == "domestic_partner"}
	coverage_household = family.active_household.immediate_family_coverage_household
	coverage_household.add_coverage_household_member(family_member)
	coverage_household.save
   end
end