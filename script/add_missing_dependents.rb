
def find_dependent(ssn,dob,first_name,middle_name,last_name)
	person = Person.where(encrypted_ssn: CensusMember.encrypt_ssn(ssn)).first
	if person == nil
		person = Person.where(first_name: first_name.to_s.strip, middle_name: middle_name.to_s.strip, last_name: last_name.to_s.strip, dob: format_date(dob)).first
	else
		return person
	end

	if person == nil
		return ArgumentError.new("dependent does not exist for provided person details")
	else
		return person
	end
end

def format_date(date)
	date = Date.strptime(date,'%m/%d/%Y')
end

filename = ''

complete_rows = []

CSV.foreach(filename, headers: :true) do |row|
	hbx_enrollment = HbxEnrollment.by_hbx_id(row["Enrollment Group ID"]).first
	hbx_enrollment_member_ids = []
	hbx_enrollment.hbx_enrollment_members.each do |hbx_em|
		hbx_enrollment_member_ids.push(hbx_em.person.hbx_id)
	end
	subscriber = hbx_enrollment.subscriber.person
	census_employee = hbx_enrollment.employee_role.census_employee
	census_dependents = []
	6.times do |i|
		if data_row["HBX ID (Dep #{i+1})"].present?
			census_dependents << CensusDependent.new({
				first_name: data_row["First Name (Dep #{i+1})"],
				middle_name: data_row["Middle Name (Dep #{i+1})"],
				last_name: data_row["Last Name (Dep #{i+1})"],
				dob: format_date(data_row["DOB (Dep #{i+1})"]),
				employee_relationship: data_row["Relationship (Dep #{i+1})"].strip == 'child' ? 'child_under_26' : data_row["Relationship (Dep #{i+1})"].strip,
				gender:  data_row["Gender (Dep #{i+1})"],
				ssn: data_row["SSN (Dep #{i+1})"].to_s.strip.gsub("-","")
				})
		end
	end
	6.times do |i|
		if data_row["HBX ID (Dep #{i+1})"] != nil
			dependent = find_dependent(data_row["SSN (Dep #{i+1})"].to_s.gsub("-",""), data_row["DOB (Dep #{i+1})"],
				data_row["First Name (Dep #{i+1})"],data_row["Middle Name (Dep #{i+1})"],data_row["Last Name (Dep #{i+1})"])
            if dependent.blank? || dependent.to_s == "dependent does not exist for provided person details"
            	begin 
            	dependent = OpenStruct.new
            	dependent.first_name = data_row["First Name (Dep #{i+1})"]
            	dependent.middle_name = data_row["Middle Name (Dep #{i+1})"]
            	dependent.last_name = data_row["Last Name (Dep #{i+1})"]
            	dependent.ssn = data_row["SSN (Dep #{i+1})"].to_s.gsub("-","")
            	dependent.dob = format_date(data_row["DOB (Dep #{i+1})"]).strftime("%Y-%m-%d")
            	dependent.employee_relationship = census_employee.census_dependents.where(first_name: dependent.first_name,
            																			  middle_name: dependent.middle_name,
            																			  last_name: dependent.last_name,
            																			  dob: dependent.dob).first.employee_relationship
            	rescue Exception=>e
            		row["Error Message"] = "Cannot find census dependent #{data_row["First Name (Dep #{i+1})"]} #{data_row["Last Name (Dep #{i+1})"]} - #{e.inspect}"
            		complete_rows.push(row)
            	end
              family_member = Factories::EnrollmentFactory.initialize_dependent(family,subscriber,dependent)
              unless family_member == nil
              	begin
              	family_member.save
              	family_member.person.gender = data_row["Gender (Dep #{i+1})"]
              	family_member.person.hbx_id =  data_row["HBX ID (Dep #{i+1})"]
              	rescue Exception=>e
              		row["Error Message"] = "#{e.inspect}"
              		complete_rows.push(row)
              	end
              	
              	begin
              		family_member.person.save           
	              	ch_member = ch.add_coverage_household_member(family_member)
	              	ch_member.save
	              	ch.save
	              	family.save
	              	if !hbx_enrollment_member_ids.include?(family_member.person.hbx_id) 
	              		new_hbx_enrollment_member = HbxEnrollmentMember.new_from(ch_member)
	              		new_hbx_enrollment_member.eligibility_date = hbx_enrollment.subscriber.eligibility_date
	              		new_hbx_enrollment_member.coverage_start_on = hbx_enrollment.subscriber.coverage_start_on
	              		hbx_enrollment.hbx_enrollment_members.push(new_hbx_enrollment_member)
	              		new_hbx_enrollment_member.save
	              		hbx_enrollment.save
	              	end
              	rescue Exception=>e
              		row["Error Message"] = "#{e.inspect}"
              		complete_rows.push(row)
              	end   
              end

            end
		end
	end
end