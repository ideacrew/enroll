all_employers = Organization.where(:employer_profile => {"$ne" => nil})

CSV.open("employer_audit_data_tab1.csv", "w") do |csv|
	csv << ["Legal Name", "DBA", "FEIN", "AASM State", "Coverage Year Start", "Coverage Year End",
			"New Hire Eligibility","Plan Offerings","Employee Count"]
	all_employers.each do |employer|
		begin
		legal_name = employer.legal_name
		dba = employer.dba
		fein = employer.fein
		state = employer.employer_profile.aasm_state
		plan_years = employer.employer_profile.plan_years
		employee_count = employer.employer_profile.roster_size
		office_locations = employer.office_locations
		addresses = []
		office_locations.each do |location|
			addresses.push(location.address.full_address)
		end
		plan_years.each do |plan_year|
			start_date = plan_year.start_on
			end_date = plan_year.end_on
			benefit_groups = plan_year.benefit_groups
			benefit_groups.each do |benefit_group|
				elected_plans = benefit_group.elected_plans.map(&:name)
				csv << [legal_name, dba, fein, state, start_date, end_date,"",elected_plans,employee_count]
			end
		end
		rescue Exception=>e
			binding.pry
		end
	end
end

## b. In a separate tab(s), please include the roster information for each group including
## i. Employee Name
## ii. Employee hire date
## iii. Date added to roster
## iv. Whether employee waived coverage or selected a plan
CSV.open("employer_audit_data_tab2.csv","w") do |csv|
	csv << ["Employer Name", "Employer FEIN", "Employee Name", "Hire Date", "Date Added to Roster", "Coverage State"]
	all_employers.each do |employer|
		begin
			employer_name = employer.legal_name
			fein = employer.fein
			census_employees = employer.employer_profile.census_employees
			census_employees.each do |census_employee|
				name = name_to_listing(census_employee)
				hire_date = census_employee.hired_on
				roster_added = census_employee.created_on
				coverage_state = enrollment_state(census_employee)
			end
		rescue Exception=>e
			binding.pry
		end
	end
end
