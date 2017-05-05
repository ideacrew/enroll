require File.join(Rails.root, "lib/mongoid_migration_task")

class RelationshipsUpdate < MongoidMigrationTask
  def migrate
    Family.all.each do |family|
      begin
        primary = family.primary_applicant
        primary_person = primary.person

        primary_person.person_relationships.each do |relation|
          dependent_person = Person.find(relation.relative_id)
          dependent_person.add_relationship(primary_person, relation.kind, family.id)
          relation.update_attributes(kind: PersonRelationship::InverseMap[kind],successor_id: dependent_person.id, predecessor_id: primary_person.id,family_id: family.id)
        end
        puts "#{family.family_members.count}, #{primary_person.person_relationships.count}"
      rescue
        puts "Bad Family Record: #{family.id}"
      end
    end
  end
end
