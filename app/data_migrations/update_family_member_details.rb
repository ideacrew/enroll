require File.join(Rails.root, "lib/mongoid_migration_task")
class UpdateFamilyMemberDetails < MongoidMigrationTask
  def migrate
    begin
      person1=Person.where(hbx_id:ENV['hbx_id_1']).first
      person2=Person.where(hbx_id:ENV['hbx_id_2']).first
      family_member = person1.primary_family.family_members.find(ENV['id'])
      unless family_member.present?
        puts "No family member is present with the given id" unless Rails.env.test?
      else
        family_member.update_attributes(is_active: true, person_id: person2.id)
        person1.person_relationships.first.update_attributes(relative_id: person2.id)
        puts "successfully updated family member" unless Rails.env.test?
      end
    rescue
      puts "Bad Record" unless Rails.env.test?
    end
  end
end


