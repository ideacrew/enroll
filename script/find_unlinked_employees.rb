## Find all people who have an employee role.
all_employee_users = User.where(:roles => {"$in" => ["employee"]}).to_a
all_employee_persons = Person.where(:employee_roles => {"$ne" => nil}).to_a

all_employee_persons_combined = []

all_employee_users.each do |employee_user|
  all_employee_persons_combined.push(employee_user.person)
end

all_employee_persons.each do |employee_person|
  all_employee_persons_combined.push(employee_person)
end

all_employee_persons_combined.uniq!

timestamp = Time.now.strftime('%Y%m%d%H%M')

error_log = File.new("find_unlinked_employees_script_errors_#{timestamp}.txt", "w")

CSV.open("unlinked_employees.csv", "w") do |csv|
  csv << ["Email", "First Name", "Last Name", "HBX ID", "Employer Name", "Current State"]
  all_employee_persons_combined.each do |employee_person|
    begin
    census_employee = employee_person.employee_roles.first.census_employee
    if census_employee.aasm_state == "eligible"
      email = employee_person.user.email
      first_name = census_employee.first_name
      last_name = census_employee.last_name
      hbx_id = employee_person.hbx_id
      employer_name = census_employee.employer_profile.organization.legal_name
      current_state = census_employee.aasm_state
      csv << [email, first_name, last_name, hbx_id, employer_name, current_state]
    end
    rescue Exception=>e
      error_log.puts("#{employee_person.inspect} - #{e.message}")
    end
  end
end
