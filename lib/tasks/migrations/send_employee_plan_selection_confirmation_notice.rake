require File.join(Rails.root, "app", "data_migrations", "send_employee_plan_selection_confirmation_notice")
# This rake task is to send employee employee plan selection confirmation (D075) notice 
# RAILS_ENV=production bundle exec rake migrations:send_employee_plan_selection_confirmation_notice ce_id='123123123'
namespace :migrations do
  desc "Rake task that sends employee plan selection confirmation notice to an employee"
  SendEmployeePlanSelectionConfirmationNotice.define_task :send_employee_plan_selection_confirmation_notice => :environment
end