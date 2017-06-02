require File.join(Rails.root, "lib/mongoid_migration_task")

class ChangeRelationshipKind < MongoidMigrationTask
  def migrate
    begin
      hbx_id = (ENV['hbx_id']).to_s
      person=Person.where(hbx_id:hbx_id).first
      # person_relation=person.person_relationships.first
      person_relation=person.person_relationships.where(:kind=>"child")
      person_relationship.update_attributes(kind: "self")
      person_relationship.save
      puts "Changed person relationship type to child with hbx_id: #{ENV['hbx_id']} " unless Rails.env.test?
    rescue
      puts "Bad Record" unless Rails.env.test?
    end
  end
end