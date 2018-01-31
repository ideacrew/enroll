puts "*"*80
puts "::: Creating Employee Roles:::"

employer_profiles = Organization.all.collect(&:employer_profile).reject(&:nil?)
employer_profiles.select(&:census_employees).each do |employer_profile|
=begin
    case employer_profile.employee_families.count
    when 1
      [employer_profile.employee_families.first]
    else
      [employer_profile.employee_families.first, employer_profile.employee_families.last]
    end.each do |family|
    census_employee = family.census_employee

    params = {
      employer_profile: employer_profile,
      first_name: census_employee.first_name,
      last_name: census_employee.last_name,
      gender: census_employee.gender,
      ssn: census_employee.ssn,
      dob: census_employee.dob,
      hired_on: census_employee.hired_on
    }
    employee, family = Factories::EnrollmentFactory.add_employee_role(**params)

    employee.person.addresses << census_employee.address
    employee.person.save
    employee
  end
=end
end

puts "::: Employees Complete :::"
