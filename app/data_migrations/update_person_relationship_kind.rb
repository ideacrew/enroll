require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdatePersonRelationshipKind < MongoidMigrationTask
  def migrate
    begin
      hbx_id = ENV['hbx_id'].to_s
      person = Person.where(hbx_id: hbx_id).first
      if person.primary_family.present?
        person_relationships = person.person_relationships.where(relative_id: person.id)
        person_relationships.each do | person_relation|
          person_relation.update_attributes(kind: "self", relative_id: person.id)
        end
        puts "Changed person relationship type to self for hbx_id: #{hbx_id}" unless Rails.env.test?
      else
        puts "The person with hbx_id: #{hbx_id} is not a primary person of any family" unless Rails.env.test?
      end
    rescue
      puts "Bad Person Record with hbx_id: #{hbx_id}" unless Rails.env.test?
    end
  end
end