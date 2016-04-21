require 'pry'
require 'csv'

filename = "Redmine-6712.csv"

CSV.foreach(filename, headers: true) do |row|
	begin
		data_row = row.to_hash
		person = Person.where(hbx_id: data_row["HBX ID"]).first
		if person == nil
			person = Person.new
			person.hbx_id = data_row["HBX ID"]
			person.first_name = data_row["First Name"]
			person.middle_name = data_row["Middle Name"]
			person.last_name = data_row ["Last Name"]
			person.full_name = person.full_name
			person.ssn = data_row["SSN"].gsub("-","")
			person.dob = data_row["DOB"].to_date
			person.gender = data_row["Gender"].downcase
			person.save

			## Give them an Address
			address = Address.new
			address.kind = data_row["Address Kind"]
			address.address_1 = data_row["Address 1"]
			address.address_2 = data_row["Address 2"]
			address.city = data_row["City"]
			address.state = data_row["State"]
			address.zip = data_row["Zip"]
			person.addresses.push(address)
			address.save
			person.save

			## Give them a phone (or phones)
			phone = Phone.new
			phone.kind = data_row["Phone Type"].downcase
			phone.full_phone_number = data_row["Phone Number"].gsub("(","").gsub(")","").sub("-","")
			person.phones.push(phone)
			phone.save

			## Give them an email
			email = Email.new
			email.kind = data_row["Email Kind"]
			email.address = data_row["Email Address"]
			person.emails.push(email)
			email.save			

			## Give them a Consumer Role
			consumer_role = ConsumerRole.new
			person.consumer_role = consumer_role
			consumer_role.is_state_resident = true
			consumer_role.is_applicant = true
			consumer_role.save
			person.save
		end
		family = person.primary_family
		consumer_role = person.consumer_role
		if family == nil
			## Make the Family
			family = Family.new
			fam_member = FamilyMember.new
			fam_member.is_primary_applicant = true
			fam_member.person_id = person._id
			family.family_members.push(fam_member)
			fam_member.save
			family.save			
		end
		household = person.primary_family.active_household
		if household == nil
			household = family.households.sort_by!{|household| household.created_at}.last
		end
		coverage_household = household.immediate_family_coverage_household
		if coverage_household == nil
			coverage_household = CoverageHousehold.new
			ch_member = CoverageHouseholdMember.new
			ch_member.family_member_id = fam_member._id
			ch_member.is_subscriber = true
			coverage_household.coverage_household_members.push(ch_member)
			ch_member.save
			household.coverage_households.push(coverage_household)
			coverage_household.is_immediate_family = true
			coverage_household.save
		end
		eg_id = data_row["Enrollment Group ID"].to_s
		hbx_enrollment = HbxEnrollment.by_hbx_id(eg_id)
		if hbx_enrollment == []
			hbx_enrollment = HbxEnrollment.new
			household.hbx_enrollments.push(hbx_enrollment)
			hbx_enrollment.coverage_household_id = coverage_household._id
			hbx_enrollment.enrollment_kind = "special_enrollment"
			hbx_enrollment.kind = data_row["Enrollment Kind"] ## Eg unassissted_qhp assisted_qhp etc 
			hbx_enrollment.effective_on = data_row["Benefit Begin Date"].to_date
			unless hbx_enrollment.is_shop?
				year = hbx_enrollment.effective_on.year.to_i
			end
			plan = Plan.where(hios_id: data_row["HIOS ID"], active_year: year).first
			hbx_enrollment.plan_id = plan._id
			hbx_enrollment.carrier_profile_id = plan.carrier_profile._id
			hbx_enrollment.hbx_id = eg_id
			hbx_enrollment.consumer_role_id = consumer_role._id
			hbx_enrollment.aasm_state = "coverage_selected"
			hbx_enrollment.save

			## Create the Hbx Enrollment Member
			hbx_enrollment_member = HbxEnrollmentMember.new
			hbx_enrollment_member.is_subscriber = true
			hbx_enrollment_member.coverage_start_on = hbx_enrollment.effective_on
			hbx_enrollment_member.applicant_id = hbx_enrollment.household.family.family_members.first._id
			hbx_enrollment_member.eligibility_date = hbx_enrollment_member.coverage_start_on.prev_month + 14.days
			hbx_enrollment.hbx_enrollment_members.push(hbx_enrollment_member)
			hbx_enrollment_member.save
			hbx_enrollment.save
		end
	rescue Exception=>e
		puts e.inspect
		puts e.backtrace
	end
end