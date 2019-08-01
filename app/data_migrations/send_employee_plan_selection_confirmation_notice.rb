require File.join(Rails.root, "lib/mongoid_migration_task")

class SendEmployeePlanSelectionConfirmationNotice < MongoidMigrationTask
  def migrate
    ce_id = ENV['ce_id'].to_s
    census_employee = CensusEmployee.find(ce_id)
    trigger_plan_selection_confirmation_notice(census_employee)
  end

  def trigger_plan_selection_confirmation_notice(census_employee)
    if !census_employee.employee_role.present?
      puts "can not send notice to ce with id #{census_employee.id} due to no employee role" unless Rails.env.test?
    elsif !census_employee.active_benefit_group_assignment.present?
      puts "can not send notice to ce with id #{census_employee.id} due to no active active_benefit_group_assignment" unless Rails.env.test?
    elsif census_employee.active_benefit_group_assignment.hbx_enrollment.nil?
      puts "can not send notice to ce with id #{census_employee.id} due to no enrollment purchased" unless Rails.env.test?
    else
      observer = Observers::NoticeObserver.new
      observer.deliver(recipient: census_employee.employee_role, event_object: census_employee.active_benefit_group_assignment.hbx_enrollment, notice_event: "initial_employee_plan_selection_confirmation")
      puts "sent plan selection confirmation notice to ce with id #{census_employee.id}" unless Rails.env.test?
    end
  end
end
