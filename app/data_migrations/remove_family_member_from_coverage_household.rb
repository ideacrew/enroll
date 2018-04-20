require File.join(Rails.root, "lib/mongoid_migration_task")

class RemoveFamilyMemberFromCoverageHousehold < MongoidMigrationTask
  def migrate
    #person_hbx_id=19810927 family_member_hbx_id=123123123
    person = Person.where(hbx_id: ENV['person_hbx_id']).first
    family_member_hbx_id = ENV['family_member_hbx_id']
    if person.blank?
      raise "Invalid hbx_id of person"
    else
      family = person.primary_family
      if family.present?
          family.active_household.family_members.each do |i|
            if i.hbx_id == family_member_hbx_id
              i.delete
              family.save
              puts "Remove family member of hbx_id:#{family_member_hbx_id} " unless Rails.env == 'test'
              return
            end
          end
      else
        raise "No Family Found"
      end
    end
  end
end