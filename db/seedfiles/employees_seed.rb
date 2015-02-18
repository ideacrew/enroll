puts "*"*80
puts "::: Creating Employee Roles:::"

er = Employer.first
ee = er.employee_families.first.employee

psn = Person.create!(
    first_name: ee.first_name, 
    last_name: ee.last_name,
    addresses: [ee.address],
    gender: ee.gender,
    ssn: ee.ssn,
    dob: ee.dob
  )

e0 = psn.employees.build
e0.employer = er
e0.hired_on = ee.hired_on
e0.save!

puts "::: Employees Complete :::"
