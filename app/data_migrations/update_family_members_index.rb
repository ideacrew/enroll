require File.join(Rails.root, "lib/mongoid_migration_task")
class UpdateFamilyMembersIndex < MongoidMigrationTask
  def migrate
    primary_person = Person.where(hbx_id: ENV['primary_hbx']).first
    dependent = Person.where(hbx_id: ENV['dependent_hbx']).first
    if primary_person.present? && dependent.present?
      if primary_person.primary_family.present?
        primary_member = primary_person.primary_family.family_members[0]
        primary_member.update_attributes(person_id: ENV['primary_id'])
        dependent_member = primary_person.primary_family.family_members[1]
        dependent_member.update_attributes(person_id: ENV['dependent_id'])
      end
      if dependent.primary_family.present?
        primary_member = dependent.primary_family.family_members[0]
        primary_member.update_attributes(is_primary_applicant: true)
        dependent_member = dependent.primary_family.family_members[1]
        dependent_member.update_attributes(is_primary_applicant: false)
      end
    else
      raise "some error person with hbx_id:#{ENV['primary_hbx']} and hbx_id:#{ENV['dependent_hbx']} not found"
    end
  end
end
