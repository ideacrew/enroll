# Takes enrollments that are terminated in Glue and terminates them in Enroll. 
filename = "imported_terminated_policies-8905.csv"

CSV.foreach(filename, headers: true) do |csv_row|
	hbx_enrollment = HbxEnrollment.by_hbx_id(csv_row["Enrollment Group ID"]).first
	end_date = Date.strptime(csv_row["Benefit End Date"],'%m/%d/%Y')
	hbx_enrollment.terminated_on = end_date
	if hbx_enrollment.benefit_group.plan_year.end_on != end_date
		hbx_enrollment.aasm_state = "coverage_terminated"
	elsif hbx_enrollment.benefit_group.plan_year.end_on == end_date
		hbx_enrollment.aasm_state = "coverage_expired"
	end
	hbx_enrollment.save!
end