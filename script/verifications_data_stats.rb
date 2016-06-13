def ssn_outstanding?(person)
  person.consumer_role.ssn_validation == 'outstanding'
end

def lawful_presence_outstanding?(person)
  person.consumer_role.lawful_presence_determination.aasm_state == 'verification_outstanding'
end

people_to_check = Person.where(
  "consumer_role.lawful_presence_determination.aasm_state" => "verification_outstanding" 
  )

puts "Candidate People: #{people_to_check.count}"

families = Family.where("family_members.person_id" => {"$in" => people_to_check.map(&:_id)})
puts "Candidate Families: #{families.count}"

count  = 0

families_for_report = families.select do |family|
  enrollments = family.enrollments.select{|e| e.currently_active? || e.future_active?}

  family_members = enrollments.inject([]) do |family_members, enrollment|
    family_members += enrollment.hbx_enrollment_members.map(&:family_member)
  end.uniq

  people = family_members.map(&:person).uniq

  if people.any?{|p| (p.consumer_role.lawful_presence_determination.vlp_authority == 'dhs' && !p.ssn.blank?) }
    false
  else
    people = people.select{|p| (p.consumer_role.lawful_presence_determination.aasm_state == 'verification_outstanding') }
    unverified = []
    people.each do |person|
      if ssn_outstanding?(person)
        unverified << person.full_name.titleize
      end

      if lawful_presence_outstanding?(person) 
        unverified << person.full_name.titleize
      end
    end

    if people.any?
      count += 1
    end
  
    unverified.empty? ? false : true
  end
end

puts count
puts families_for_report.count