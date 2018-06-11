require File.join(Rails.root, "lib/mongoid_migration_task")

class RemoveFamilyMember < MongoidMigrationTask
  def migrate
    person = Person.where(hbx_id: ENV['person_hbx_id']).first
    if person.blank?
      raise "Invalid hbx_id of person"
    else
      family = person.primary_family
      if family.present?
        first_name = ENV["person_first_name"].try(:split,",") || []
        last_name = ENV["person_last_name"].try(:split,",")|| []
        family_members_to_delete = person.primary_family.family_members.select {|fm| first_name.map(&:downcase).include?(fm.person.first_name.downcase) && last_name.map(&:downcase).include?(fm.person.last_name.downcase)}
        family_members_to_delete.map(&:destroy)
        person.save
      else
        raise "No Family Found"
      end
    end
  end
end