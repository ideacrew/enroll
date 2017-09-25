require File.join(Rails.root, "lib/mongoid_migration_task")

class ChangePersonFamilyMemberLinkage < MongoidMigrationTask

  def migrate
    person = Person.where(hbx_id: ENV['hbx_id'])
    family = Family.where("family_members._id" => BSON::ObjectId(ENV['family_member_id']))
    family_member = family.family_members.detect{|fm| fm.id.to_s == ENV['family_member_id']}
    family_member.update_attributes!(:person_id => person._id)
  end

end