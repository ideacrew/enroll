require 'csv'

filename = "Redmine-7304.csv"

def select_benefit_package(title, benefit_coverage_period)
	benefit_coverage_period.benefit_packages.each do |benefit_package|
		if benefit_package.title == title
			return benefit_package
		end
	end
end

def select_benefit_group(benefit_group_title,benefit_groups)
	benefit_groups.each do |benefit_group|
		if benefit_group_title.to_s.strip == benefit_group.title.to_s.strip
			return benefit_group
		end
	end
end

def select_benefit_group_assignment(correct_benefit_group,benefit_group_assignments)
	correct_benefit_group_assignment = nil
	benefit_group_assignments.each do |benefit_group_assignment|
		if benefit_group_assignment.benefit_group_id == correct_benefit_group._id
			correct_benefit_group_assignment = benefit_group_assignment
		end
	end
	return correct_benefit_group_assignment
end

def get_all_benefit_groups(organization)
	all_benefit_groups = []
	organization.employer_profile.plan_years.each do |plan_year|
		plan_year.benefit_groups.each do |benefit_group|
			all_benefit_groups.push(benefit_group)
		end
	end
	return all_benefit_groups
end

def select_or_create_benefit_group_assignment(benefit_group_title,organization,census_employee)
	benefit_group_assignments = census_employee.benefit_group_assignments
	all_benefit_groups = get_all_benefit_groups(organization)
	correct_benefit_group = select_benefit_group(benefit_group_title,all_benefit_groups)
	correct_benefit_group_assignment = select_benefit_group_assignment(correct_benefit_group,benefit_group_assignments)
	if correct_benefit_group_assignment == nil
		correct_benefit_group_assignment = BenefitGroupAssignment.new_from_group_and_census_employee(correct_benefit_group,census_employee)
	end # creates the correct benefit group assignment if it doesn't exist.
	return correct_benefit_group_assignment
end # ends the function

def format_date(date)
	date = Date.strptime(date,'%m/%d/%Y')
end

def find_census_employee(subscriber_params)
	census_employee = CensusEmployee.where(encrypted_ssn: CensusMember.encrypt_ssn(subscriber_params["ssn"])).first
	if census_employee == nil
		census_employee = CensusEmployee.where(first_name: subscriber_params["first_name"], 
											   middle_name: subscriber_params["middle_name"],
											   last_name: subscriber_params["last_name"],
											   dob: subscriber_params["dob"]).first
	end
	return census_employee
end

def create_person_details(subscriber_params)
	person_details = Forms::EmploymentRelationship.new
	person_details.name_pfx = subscriber_params["name_pfx"]
	person_details.first_name = subscriber_params["first_name"]
	person_details.middle_name = subscriber_params["middle_name"]
	person_details.last_name = subscriber_params["last_name"]
	person_details.name_sfx = subscriber_params["name_sfx"]
	person_details.gender = subscriber_params["gender"]
	return person_details
end

def find_dependent(ssn,dob,first_name,middle_name,last_name)
	person = Person.where(encrypted_ssn: CensusMember.encrypt_ssn(ssn)).first
	if person == nil
		person = Person.where(first_name: first_name.strip, middle_name: middle_name.strip, last_name: last_name.strip, dob: format_date(dob))
	else
		return person
	end
	if person == nil
		return ArgumentError.new("dependent does not exist for provided person details")
	else
		return person
	end
end

def select_employee_role(employer_profile_id, employee_roles)
	correct_employee_role = employee_roles.detect{|employee_role| employee_role.employer_profile_id == employer_profile_id}
	return correct_employee_role
end

## Just for clarification 
# EnrollmentFactory#construct_consumer_role
# EnrollmentFactory#initialize_dependent
# dependent_person.build_consumer_role(is_applicant: false)
# EnrollmentFactory#construct_employee_role
# EnrollmentFactory#initialize_dependent
# dependent_person.employee_roles.build(employer_profile: employer_profile, hired_on: hired_on)

CSV.foreach(filename, headers: :true) do |row|
	begin
		data_row = row.to_hash
		subscriber = Person.where(hbx_id: data_row['HBX ID']).first
		subscriber_params = {"name_pfx" => data_row["Name Prefix"],
									 "first_name" => data_row["First Name"],
									 "middle_name" => data_row["Middle Name"],
									 "last_name" => data_row["Last Name"],
									 "name_sfx" => data_row["Name Suffix"],
									 "ssn" => data_row["SSN"].gsub("-",""),
									 "dob" => format_date(data_row["DOB"]),
									 "gender" => data_row["Gender"].downcase,
									 "no_ssn" => 0
									}
		census_employee = find_census_employee(subscriber_params)
		person_details = create_person_details(subscriber_params)
		unless data_row["Employer FEIN"] == nil
			organization = Organization.where(fein: data_row["Employer FEIN"].gsub("-","")).first
		end
		if subscriber == nil
			if data_row["Employer FEIN"] == nil # for IVL
				next
				subscriber_params = {"name_pfx" => data_row["Name Prefix"],
									 "first_name" => data_row["First Name"],
									 "middle_name" => data_row["Middle Name"],
									 "last_name" => data_row["Last Name"],
									 "name_sfx" => data_row["Name Suffix"],
									 "ssn" => data_row["SSN"].gsub("-",""),
									 "dob" => format_date(data_row["DOB"]),
									 "gender" => data_row["Gender"].downcase,
									 "no_ssn" => 0
									}
				person = Factories::EnrollmentFactory.initialize_person(nil,data_row["Name Prefix"],data_row["First Name"], data_row["Middle Name"],
                               data_row["Last Name"], data_row["Name Suffix"], data_row["SSN"].gsub("-",""), format_date(data_row["DOB"]), data_row["Gender"].downcase, nil, no_ssn=nil)
			elsif data_row["Employer FEIN"] != nil # for SHOP
				unless census_employee == nil
					benefit_group_assignment = select_or_create_benefit_group_assignment(data_row["Benefit Package/Benefit Group"],
																						 organization,census_employee)
					employee_role = Factories::EnrollmentFactory.construct_employee_role(nil,census_employee,person_details).first
					employee_role.benefit_group_id = benefit_group_assignment.benefit_group_id
					subscriber = employee_role.person
					##  Give the subscriber the correct HBX ID.
					subscriber.hbx_id = data_row["HBX ID"]
					subscriber.save
					## Do the same for any dependents. 
					if data_row["HBX ID (Dep 1)"] != nil
						dependent = find_dependent(data_row["SSN (Dep 1)"].gsub("-",""), data_row["DOB (Dep 1)"],
									   data_row["First Name (Dep 1)"],data_row["Middle Name (Dep 1)"],data_row["Last Name (Dep 1)"])
						dependent.hbx_id = data_row["HBX ID (Dep 1)"]
						dependent.save
					end
					if data_row["HBX ID (Dep 2)"] != nil
						dependent = find_dependent(data_row["SSN (Dep 2)"].gsub("-",""), data_row["DOB (Dep 2)"],
									   data_row["First Name (Dep 2)"],data_row["Middle Name (Dep 2)"],data_row["Last Name (Dep 2)"])
						dependent.hbx_id = data_row["HBX ID (Dep 2)"]
						dependent.save
					end
					if data_row["HBX ID (Dep 3)"] != nil
						dependent = find_dependent(data_row["SSN (Dep 3)"].gsub("-",""), data_row["DOB (Dep 3)"],
									   data_row["First Name (Dep 3)"],data_row["Middle Name (Dep 3)"],data_row["Last Name (Dep 3)"])
						dependent.hbx_id = data_row["HBX ID (Dep 3)"]
						dependent.save
					end
					if data_row["HBX ID (Dep 4)"] != nil
						dependent = find_dependent(data_row["SSN (Dep 4)"].gsub("-",""), data_row["DOB (Dep 4)"],
									   data_row["First Name (Dep 4)"],data_row["Middle Name (Dep 4)"],data_row["Last Name (Dep 4)"])
						dependent.hbx_id = data_row["HBX ID (Dep 4)"]
						dependent.save
					end
					if data_row["HBX ID (Dep 5)"] != nil
						dependent = find_dependent(data_row["SSN (Dep 5)"].gsub("-",""), data_row["DOB (Dep 5)"],
									   data_row["First Name (Dep 5)"],data_row["Middle Name (Dep 5)"],data_row["Last Name (Dep 5)"])
						dependent.hbx_id = data_row["HBX ID (Dep 5)"]
						dependent.save
					end
					if data_row["HBX ID (Dep 6)"] != nil
						dependent = find_dependent(data_row["SSN (Dep 6)"].gsub("-",""), data_row["DOB (Dep 6)"],
									   data_row["First Name (Dep 6)"],data_row["Middle Name (Dep 6)"],data_row["Last Name (Dep 6)"])
						dependent.hbx_id = data_row["HBX ID (Dep 6)"]
						dependent.save
					end
				else
					raise ArgumentError.new("census employee does not exist for provided person details")
				end
			end
		end
		family = subscriber.primary_family
		household = family.active_household
		hbx_enrollment = HbxEnrollment.new
		benefit_group_assignment = select_or_create_benefit_group_assignment(data_row["Benefit Package/Benefit Group"],organization,census_employee)
		if subscriber.employee_roles.size == 0
			Factories::EnrollmentFactory.construct_employee_role(nil,census_employee,person_details)
		end
		hbx_enrollment.employee_role_id = select_employee_role(organization.employer_profile._id,subscriber.employee_roles)._id
		household.hbx_enrollments.push(hbx_enrollment)
		coverage_household = household.immediate_family_coverage_household
		hbx_enrollment.coverage_household_id = coverage_household._id
		hbx_enrollment.enrollment_kind = "open_enrollment"
		hbx_enrollment.kind = data_row["Enrollment Kind"]
		hbx_enrollment.effective_on = format_date(data_row["Benefit Begin Date"])
		hbx_enrollment.benefit_group_assignment_id = benefit_group_assignment._id
		hbx_enrollment.benefit_group_id = benefit_group_assignment.benefit_group_id
		year = data_row["Plan Year"]
		plan = Plan.where(hios_id: data_row["HIOS ID"], active_year: year).first
		hbx_enrollment.plan_id = plan._id
		hbx_enrollment.carrier_profile_id = plan.carrier_profile._id
		hbx_enrollment.hbx_id = data_row["Enrollment Group ID"].to_s
		hbx_enrollment.save
		hbx_enrollment_member = HbxEnrollmentMember.new
		hbx_enrollment_member.is_subscriber = true
		hbx_enrollment_member.coverage_start_on = hbx_enrollment.effective_on
		hbx_enrollment_member.applicant_id = family.family_members.first._id
		hbx_enrollment_member.eligibility_date = hbx_enrollment_member.coverage_start_on.prev_month + 14.days
		hbx_enrollment.hbx_enrollment_members.push(hbx_enrollment_member)
		hbx_enrollment_member.save
		hbx_enrollment.aasm_state = "coverage_selected"
		hbx_enrollment.save
		
		if benefit_group_assignment.hbx_enrollment_id == nil
			benefit_group_assignment.hbx_enrollment_id = hbx_enrollment._id
		end
		if data_row["Date Plan Selected"] != nil
			hbx_enrollment.submitted_at = format_date(data_row["Date Plan Selected"]).to_datetime
		else
			hbx_enrollment.submitted_at = hbx_enrollment.effective_on.to_datetime
		end
		hbx_enrollment.save
	rescue Exception=>e
		puts e.inspect
		binding.pry
		puts "-"*100
		#puts e.backtrace
	end
end

# CSV.foreach(filename, headers: true) do |row|
# 	begin
# 		data_row = row.to_hash
# 		person = Person.where(hbx_id: data_row["HBX ID"]).first
# 		if person == nil
# 			person = Person.new
# 			person.hbx_id = data_row["HBX ID"]
# 			person.first_name = data_row["First Name"]
# 			person.middle_name = data_row["Middle Name"]
# 			person.last_name = data_row ["Last Name"]
# 			person.full_name = person.full_name
# 			person.ssn = data_row["SSN"].gsub("-","")
# 			person.dob = data_row["DOB"].to_date
# 			person.gender = data_row["Gender"].downcase
# 			person.save

# 			## Give them an Address
# 			address = Address.new
# 			address.kind = data_row["Address Kind"]
# 			address.address_1 = data_row["Address 1"]
# 			address.address_2 = data_row["Address 2"]
# 			address.city = data_row["City"]
# 			address.state = data_row["State"]
# 			address.zip = data_row["Zip"]
# 			person.addresses.push(address)
# 			address.save
# 			person.save

# 			## Give them a phone (or phones)
# 			phone = Phone.new
# 			phone.kind = data_row["Phone Type"].downcase
# 			phone.full_phone_number = data_row["Phone Number"].gsub("(","").gsub(")","").sub("-","")
# 			person.phones.push(phone)
# 			phone.save

# 			## Give them an email
# 			email = Email.new
# 			email.kind = data_row["Email Kind"]
# 			email.address = data_row["Email Address"]
# 			person.emails.push(email)
# 			email.save			

# 			## Give them a Consumer Role
# 			consumer_role = ConsumerRole.new
# 			person.consumer_role = consumer_role
# 			consumer_role.is_state_resident = true
# 			consumer_role.is_applicant = true
# 			consumer_role.save
# 			person.save
# 		end
# 		family = person.primary_family
# 		consumer_role = person.consumer_role
# 		if family == nil
# 			## Make the Family
# 			family = Family.new
# 			fam_member = FamilyMember.new
# 			fam_member.is_primary_applicant = true
# 			fam_member.person_id = person._id
# 			family.family_members.push(fam_member)
# 			fam_member.save
# 			family.save			
# 		end
# 		household = person.primary_family.active_household
# 		if household == nil
# 			household = family.households.sort_by!{|household| household.created_at}.last
# 		end
# 		coverage_household = household.immediate_family_coverage_household
# 		if coverage_household == nil
# 			coverage_household = CoverageHousehold.new
# 			ch_member = CoverageHouseholdMember.new
# 			ch_member.family_member_id = fam_member._id
# 			ch_member.is_subscriber = true
# 			coverage_household.coverage_household_members.push(ch_member)
# 			ch_member.save
# 			household.coverage_households.push(coverage_household)
# 			coverage_household.is_immediate_family = true
# 			coverage_household.save
# 		end
# 		eg_id = data_row["Enrollment Group ID"].to_s
# 		hbx_enrollment = HbxEnrollment.by_hbx_id(eg_id).first
# 		if hbx_enrollment == nil
# 			hbx_enrollment = HbxEnrollment.new
# 			household.hbx_enrollments.push(hbx_enrollment)
# 			hbx_enrollment.coverage_household_id = coverage_household._id
# 			hbx_enrollment.enrollment_kind = "special_enrollment"
# 			hbx_enrollment.kind = data_row["Enrollment Kind"] ## Eg unassissted_qhp assisted_qhp etc 
# 			hbx_enrollment.effective_on = data_row["Benefit Begin Date"].to_date
# 			unless hbx_enrollment.is_shop?
# 				year = hbx_enrollment.effective_on.year.to_i
# 			end
# 			hbx_enrollment.benefit_coverage_period_id = BenefitCoveragePeriod.find_by_date(hbx_enrollment.effective_on)._id
# 			hbx_enrollment.benefit_package_id = select_benefit_package(data_row["Benefit Package Title"], 
# 																	   BenefitCoveragePeriod.find(hbx_enrollment.benefit_coverage_period_id))._id
# 			plan = Plan.where(hios_id: data_row["HIOS ID"], active_year: year).first
# 			hbx_enrollment.plan_id = plan._id
# 			hbx_enrollment.carrier_profile_id = plan.carrier_profile._id
# 			hbx_enrollment.hbx_id = eg_id
# 			hbx_enrollment.consumer_role_id = consumer_role._id
# 			hbx_enrollment.aasm_state = "coverage_selected"
# 			if data_row["Plan Selected"] != nil
# 				hbx_enrollment.submitted_at = data_row["Date Plan Selected"].to_time
# 			else
# 				hbx_enrollment.submitted_at = hbx_enrollment.effective_on.to_time
# 			end
# 			hbx_enrollment.save

# 			## Create the Hbx Enrollment Member
# 			hbx_enrollment_member = HbxEnrollmentMember.new
# 			hbx_enrollment_member.is_subscriber = true
# 			hbx_enrollment_member.coverage_start_on = hbx_enrollment.effective_on
# 			hbx_enrollment_member.applicant_id = family.family_members.first._id
# 			hbx_enrollment_member.eligibility_date = hbx_enrollment_member.coverage_start_on.prev_month + 14.days
# 			hbx_enrollment.hbx_enrollment_members.push(hbx_enrollment_member)
# 			hbx_enrollment_member.save
# 			hbx_enrollment.save
# 		end
# 	rescue Exception=>e
# 		puts e.inspect
# 		puts e.backtrace
# 	end
# end