## This script takes employees who have created an account and have a linkage and changes their aasm state.

filename = 'unlinked_employees.csv'

CSV.foreach(filename, headers: true) do |row|
  begin
    data_row = row.to_hash
    person = Person.where(hbx_id: data_row["HBX ID"]).first
    employee_role = person.employee_roles.first
    census_employee = employee_role.census_employee
    if census_employee.aasm_state == "eligible"
      census_employee.employee_role_id = employee_role.id
      census_employee.link_employee_role
      #census_employee.aasm_state = "employee_role_linked"
      census_employee.save
    end
  rescue Exception=>e
    puts "#{census_employee.inspect} - #{e.message}"
  end
end
