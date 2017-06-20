

# This ER had a terminated plan year with a custom end_on date i.e., plan year duration is less than 12 months

# 16410

organization = Organization.where(legal_name: /Preventive Measures Of Washing/i).first
census_employees = organization.employer_profile.census_employees
census_employees.each do |ce|
  ce.save
  ce.benefit_group_assignments.each do |bga|
    unless bga.valid?
      if bga.end_on.present? && bga.end_on > bga.benefit_group.plan_year.end_on
        if bga.update_attributes(end_on: bga.benefit_group.plan_year.end_on)
          puts "update benefit_group_assignment end_on date for #{ce.full_name}"
        else
          puts "check #{ce.full_name}"
        end
      end
    end
  end
end


# 16505

# Benefit Group Mismatch Issue. BG & BGA must point to same plan year, here BG pointing to 2015, whereas BGA is pointing to 2016 plan year which is incorrect
census_employee = census_employees.where(first_name: 'Jessica', last_name: 'Jones').first
# This is 2015 enrollment
enrollment = HbxEnrollment.by_hbx_id('213881').first
bga = census_employee.benefit_group_assignments.where(benefit_group_id: enrollment.benefit_group.id).first
if enrollment.update_attributes(benefit_group_assignment_id: bga.id) && bga.update_attributes!(hbx_enrollment_id: enrollment.id)
  puts "Fixed benefit_group mismatch issue"
end

# Only one benefit group assignment has this issue.
invalid_bga = census_employee.benefit_group_assignments.detect {|bga| !bga.valid? }
invalid_bga.update_attributes(hbx_enrollment_id: nil)

if census_employees.where(first_name: 'Jessica', last_name: 'Jones').first.save
  puts "Issue fixed for #{census_employee.full_name}"
else
  census_employees.where(first_name: 'Jessica', last_name: 'Jones').first.benefit_group_assignments.each do |bga|
    if bga.end_on.present? && bga.end_on > bga.benefit_group.plan_year.end_on
      if bga.update_attributes(end_on: bga.benefit_group.plan_year.end_on)
        puts "update benefit_group_assignment end_on date for Jessica Jones"
      else
        puts "check Jessica Jones!!!"
      end
    end
  end
end



# 16512

census_employee = CensusEmployee.where(first_name: "Michael", middle_name: nil, last_name: "Mercier").first
# Only one benefit group assignment has this issue.
bga = census_employee.benefit_group_assignments.detect {|bga| !bga.valid? }
enrollment_ids = census_employee.employee_role.person.primary_family.active_household.hbx_enrollments.select { |enr| enr.benefit_group_assignment_id == bga.id }.map(&:hbx_id)

census_employee.benefit_group_assignments.detect {|bga| !bga.valid? }.unset(:hbx_enrollment_id)
enrollment_ids.each do |hbx_id|
  enrollment = HbxEnrollment.by_hbx_id(hbx_id)[0]
  next if enrollment.benefit_group_assignment.benefit_group == enrollment.benefit_group
  bga = census_employee.benefit_group_assignments.where(benefit_group_id: enrollment.benefit_group.id).first
  if enrollment.update_attributes!(benefit_group_assignment_id: bga.id)
    puts "Fixed benefit_group mismatch issue"
  end
end
if CensusEmployee.where(first_name: "Michael", middle_name: nil, last_name: "Mercier").first.save
  puts "Fixed issues for #{census_employee.full_name}"
else
  puts "Check #{census_employee.full_name}"
end

