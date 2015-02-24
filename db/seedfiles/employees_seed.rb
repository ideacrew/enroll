require 'factories/enrollment_factory'

puts "*"*80
puts "::: Creating Employee Roles:::"

[Employer.first, Employer.last].each do |employer|
  employer.employee_families.each do |census_employee_family|
    census_employee = census_employee_family.employee
    person = Person.create!(
        first_name: census_employee.first_name,
        last_name: census_employee.last_name,
        addresses: [census_employee.address],
    )
    employee = EnrollmentFactory.add_employee_role(
      person: person,
      employer: employer,
      gender: census_employee.gender,
      ssn: census_employee.ssn,
      dob: census_employee.dob,
      hired_on: census_employee.hired_on
    )
  end
end

puts "::: Employees Complete :::"
