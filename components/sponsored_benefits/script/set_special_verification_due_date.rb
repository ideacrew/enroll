def get_families
  #Family.by_enrollment_individual_market.where(:'households.hbx_enrollments.aasm_state' => "enrolled_contingent")
  Family.where("family_members.person_id" => {"$in" => get_people_to_check.map(&:_id)})
end

def families_without_spec_date
  #Family.by_enrollment_individual_market.where(:'households.hbx_enrollments.aasm_state' => "enrolled_contingent", :'households.hbx_enrollments.special_verification_period' => {:$exists => 0})
  Family.where("family_members.person_id" => {"$in" => get_people_to_check.map(&:_id)})
end

def get_people_to_check
  Person.where("consumer_role.lawful_presence_determination.aasm_state" => "verification_outstanding")
end


def set_date
  families = get_families
  problem_counter = 0
  families.each do |family|
    begin
      enrollments = family.enrollments.select{|e| e.currently_active? || e.future_active?}
      enrollments.each do |enrollment|
        enrollment.special_verification_period = Date.new(2016, 9, 11)
        enrollment.save
      end
    rescue => e
      problem_counter +=1
      puts "*** Problem #{problem_counter} ***"
      puts "The problem occurred for family with id: #{family.id}, Hbx enrollment id: #{enrollment.id}."
      puts e.message
      puts "***********************************"
    end
    if problem_counter > 0
      puts "You have #{problem_counter} problems."
    end
  end
end

def init_fix
  puts "#{families_without_spec_date.count} families need to be fixed."
  puts "***************************************************"
  puts "** START datafix script... **"
  set_date
end

init_fix





