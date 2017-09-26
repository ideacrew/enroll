require File.join(Rails.root, "lib/mongoid_migration_task")
class ChangePersonIdForFamilyMember < MongoidMigrationTask
  def migrate
    primary_person = Person.where(hbx_id: ENV['person_hbx_id']).first
    dependent_person = Person.where(hbx_id: ENV['dependent_hbx_id']).first
    if primary_person.present? && dependent_person.present?
      family_member = primary_person.primary_family.family_members.where(id: ENV['family_member_id'].to_s).first
      family_member.update(person_id:dependent_person.id)
    else
      raise "some error person with hbx_id:#{ENV['primary_hbx']} and hbx_id:#{ENV['dependent_hbx']} not found"
    end
  end
end