require File.join(Rails.root, "lib/mongoid_migration_task")

class AddMissingCoverageHouseholdMember < MongoidMigrationTask
  def migrate
    person = Person.where(hbx_id: ENV['hbx_id']).first
    relative = person.present? ? person.primary_family.family_members.detect {|rel| rel.relationship == ENV['relation']} : nil
    if person.nil?
      raise "Invalid Hbx Id"
    else
      raise "Relation Ship #{ENV['relation']} not found" if relative.nil?
    end
    if person.primary_family.active_household.immediate_family_coverage_household.coverage_household_members.where(:family_member_id => relative.id).length >= 1
      puts "#{ENV['relation']} is already a coverage household member"
    else
      person.primary_family.active_household.add_household_coverage_member(relative)
      person.primary_family.active_household.coverage_households.map(&:save)
      person.primary_family.active_household.save
      person.primary_family.save
    end
  end
end
