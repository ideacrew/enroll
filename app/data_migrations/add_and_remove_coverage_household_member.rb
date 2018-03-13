require File.join(Rails.root, "lib/mongoid_migration_task")

class AddAndRemoveCoverageHouseholdMember < MongoidMigrationTask
  def migrate
    primary_person = Person.where(hbx_id: ENV['primary_hbx_id'])
    action = ENV["action"]
    family_member_ids = ENV["family_member_ids"]

    if primary_person.size != 1
      raise "Invalid Hbx Id"
    end

    @active_household = primary_person.first.primary_family.active_household


    family_members = [family_member_ids].split(",").flatten.collect {|id| FamilyMember.find(id)}

    if action == "add_chm"
      family_members.each {|family_member| add_coverage_household_member(family_member)}
    elsif action == "remove_chm"
      family_members.each {|family_member| remove_coverage_household_member(family_member)}
    else
      return "Please provide an action."
    end

    @active_household.save!

    puts "******* Job Done ********" unless Rails.env.test?
  end

  def add_coverage_household_member family_member
    @active_household.add_household_coverage_member(family_member)
    puts "Added Coverage Household member record" unless Rails.env.test?
  end

  def remove_coverage_household_member family_member
    @active_household.remove_family_member(family_member)
    puts "Removed Coverage Household member record" unless Rails.env.test?
  end
end
