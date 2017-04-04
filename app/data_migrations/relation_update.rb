Family.all.each do |family|
  primary = family.primary_applicant
  primary_person = primary.person

  primary_person.person_relationships.each do |relation|
    family_member = family.family_members.where(person_id: relation.relative_id).first
    family_member.add_relationship(primary, relation.kind) if family_member.present?
  end

  p "#{family.family_members.count}, #{family.person_relationships.count}"
  primary_person.person_relationships.delete_all
end
