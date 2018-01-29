require 'csv'

def find_created_at_for_verification_type(person, v_type)
  case v_type
  when "DC Residency"
    last_local_residency_responses_created_at(person)
  when 'Social Security Number'
    ssa_responses_created_at person
  when 'American Indian Status', 'Immigration status'
    (person.ssn || person.consumer_role.is_native?) ? ssa_responses_created_at(person) : vlp_responses_created_at(person)
  when 'Citizenship'
    ssa_responses_created_at(person)
  end
end

def last_ssa_responses_created_at person
  ssa_response = person.consumer_role.lawful_presence_determination.ssa_responses.order_by(:"created_at".desc).first.try(:created_at)
  ssa_response.present? ssa_response.created_at
end

def last_vlp_responses_created_at person
  person.consumer_role.lawful_presence_determination.vlp_responses.order_by(:"created_at".desc).first.try(:created_at)
end

def last_local_residency_responses_created_at person
  person.consumer_role.local_residency_responses.order_by(:"created_at".desc).first.try(:created_at)
end

file_name = "#{Rails.root}/monthly_outstanding_verification_report_#{TimeKeeper.date_of_record.strftime("%m_%d_%Y")}.csv"

outstanding_people = Person.where({ :"consumer_role" => {"$exists" => true},  
                                    :"consumer_role.aasm_state" => "verification_outstanding"
                                  })

CSV.open(file_name,"w") do |csv|
   csv << [ "Subscriber ID",
            "Member ID",
            "First Name", 
            "Last Name",
            "Verification Type",
            "Verification Created at (Response Received at)",
            "Verification Due Date"
          ]

  outstanding_people.each do |person|
    person.consumer_role.outstanding_verification_types.each do |v_type|
      person.families.each do |family|
        active_enrollments = family.active_household.hbx_enrollments.enrolled.where(:"hbx_enrollment_members.applicant_id" => family.family_members.where(person_id: person.id).first.id)
        if active_enrollments.present?
          active_enrollments.each do |enrollment|

            sv = person.consumer_role.special_verifications.where(verification_type: v_type).order_by(:"created_at".desc).first
            created_date = find_created_at_for_verification_type(person, v_type)

            csv <<  [  enrollment.subscriber.person.hbx_id,
                      person.hbx_id,
                      person.first_name,
                      person.last_name,
                      v_type,
                      created_date,
                      sv.present? ? sv.due_date : "N/A"
                    ]
          end
        end
      end
    end
  end
end
