all_employers = Organization.where(:employer_profile => {"$ne" => nil})

CSV.open("employer_audit_data_tab1.csv", "w") do |csv|
	csv << ["Legal Name", "DBA", "FEIN", "AASM State", "Coverage Year Start", "Coverage Year End",
			"Plan Offerings","Employee Count"]
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
			puts e
		end
	end
end

CSV.open("employer_audit_data_tab2.csv","w") do |csv|
	csv << ["Employer Name", "Employer FEIN", "Employee Name", "Hire Date", "Date Added to Roster", "Coverage State"]
	all_employers.each do |employer|
		begin
			employer_name = employer.legal_name
			fein = employer.fein
			census_employees = employer.employer_profile.census_employees
			census_employees.each do |census_employee|
				name = census_employee.last_name
				hire_date = census_employee.hired_on
				roster_added = census_employee.created_at
				coverage_state = census_employee.active_benefit_group_assignment.try(:aasm_state)
				if coverage_state.present?
					coverage_state = coverage_state.humanize
				end
				csv << [employer_name, fein, name, hire_date, roster_added, coverage_state]
			end
		rescue Exception=>e
			puts e
		end
	end
end
