require File.join(Rails.root, "lib/mongoid_migration_task")

class RevertCeTermination < MongoidMigrationTask
  def migrate
    begin
      census_employee = CensusEmployee.find(ENV["census_employee_id"].to_s)
      from_state = census_employee.aasm_state
      census_employee.update_attributes(aasm_state:"employee_role_linked")
      census_employee.unset(:employment_terminated_on, :coverage_terminated_on)
      census_employee.workflow_state_transitions << WorkflowStateTransition.new(from_state: from_state, to_state: census_employee.aasm_state)
      puts "Reverted Employee Termination" unless Rails.env.test?
    rescue => e
      puts "#{e}"
    end
  end
end
