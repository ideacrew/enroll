require File.join(Rails.root, "lib/mongoid_migration_task")

class TerminateCensusEmployee < MongoidMigrationTask

  # collect all census empolyees who are in employee_termination_pending state, even after their employment_terminated_on date passed and
  # then terminate their employee roles.
  def migrate
    count = 0
    censusemployee=CensusEmployee.where(aasm_state:'employee_termination_pending').select{ |censusemployee| censusemployee.employment_terminated_on.strftime('%Y-%m-%d') <= Date.today.strftime('%Y-%m-%d')}
    if censusemployee.present?
      censusemployee.each do |employee|
        employee.terminate_employee_role! if employee.may_terminate_employee_role?
        puts "updated census employee #{employee.full_name} employment_terminated_on:#{employee.employment_terminated_on} termination status:#{employee.aasm_state}"
        count += 1
      end
    else
      puts "No census employees found"
    end
    puts "total census employees updated #{count}"
  end
end
