require File.join(Rails.root, "lib/mongoid_migration_task")

class RemoveErroneousPersonrelationshipRecords < MongoidMigrationTask
  def migrate
    person = Person.where(hbx_id: ENV['hbx_id']).first 
    ids =  (person.primary_family.family_members.where(:is_primary_applicant => false).uniq.map(&:person_id).map(&:to_s))
    person.person_relationships.keep_if{|person_relationship| ids.include?(person_relationship.relative_id.to_s)}
    puts "removed erroneous records"
  end
end

