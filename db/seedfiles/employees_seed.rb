require 'factories/enrollment_factory'

puts "*"*80
puts "::: Creating Employee Roles:::"

<<<<<<< HEAD
[EmployerProfile.first, EmployerProfile.last].each do |employer|
  employer.employee_families.each do |family|
=======
[Organization.first, Organization.last].each do |organization|
  organization.employer_profile.employee_families.each do |family|
>>>>>>> 898ad06ab4d2968b9a05dc7c3dea20bed5b80036
    census_employee = family.census_employee
    person = Person.create!(
        first_name: census_employee.first_name,
        last_name: census_employee.last_name,
        addresses: [census_employee.address],
    )
    employee = EnrollmentFactory.add_employee_role(
      person: person,
      employer_census_family: family,
      gender: census_employee.gender,
      ssn: census_employee.ssn,
      dob: census_employee.dob,
      hired_on: census_employee.hired_on
    )
  end
end

puts "::: Employees Complete :::"
