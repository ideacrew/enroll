require File.join(Rails.root, "lib/mongoid_migration_task")

class RemoveCoverageHouseholdMember < MongoidMigrationTask
  def migrate
    begin
      person = Person.where(hbx_id: ENV['person_hbx_id'])
      family_member = FamilyMember.find(ENV['family_member_id'].to_s)
      if person.blank?
        puts "Invalid hbx_id of person"  unless Rails.env.test?
      else
        ch = person.first.primary_family.active_household.coverage_households.where(:is_immediate_family => true).first
        chm = ch.remove_family_member(family_member)
        ch.save
        puts "remove family member from coverage household: #{family_member.id}" unless Rails.env.test?
      end
    rescue Exception => e
      puts e.message
    end
  end 
end
