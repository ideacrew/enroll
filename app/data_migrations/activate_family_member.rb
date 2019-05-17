require File.join(Rails.root, "lib/mongoid_migration_task")

class ActivateFamilyMember < MongoidMigrationTask
  def migrate
      begin
        family_member = FamilyMember.find(ENV['family_member_id'].to_s)
        if family_member.nil? 
          puts "no family member was found with given id for #{family_member_id}" unless Rails.env.test?
        elsif family_member.person.nil?
          puts "no person exist with family member with given id for #{family_member_id}" unless Rails.env.test?
        end
        if family_member.is_active?
          puts "The family member #{family_member} is already active" unless Rails.env.test?
        else
          family_member.update_attributes(is_active:true)
          family_member.save
          puts "The family member #{family_member} has been activated" unless Rails.env.test?
        end
      rescue Exception => e
        puts "Exception #{e} occured for family_member #{family_member_id}" unless Rails.env.test?
      end
  end
end
