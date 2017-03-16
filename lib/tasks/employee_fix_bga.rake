namespace :employee do
  desc "set benefit group to active"
  task :fix_bga => [:environment] do
    er = Person.where(hbx_id:19750273).first.active_employee_roles.first
    er.census_employee.benefit_group_assignments.last.update(is_active:true)
  end
end