require File.join(Rails.root, "lib/mongoid_migration_task")

class DeactivateBenefitGroupAssignment < MongoidMigrationTask
  def migrate
    begin
      census_employee = CensusEmployee.by_ssn(ENV['ce_ssn']).first
      if census_employee.nil?
        puts "No census employee was found with given ssn"
      else
        bg_assignment=census_employee.benefit_group_assignments.where(id:ENV['bga_id']).first
        if bg_assignment.is_active? 
          if bg_assignment.plan_year.nil?
            puts "The benefit group assignment has no plan year attached"
          else
            end_on = bg_assignment.plan_year.end_on 
            bg_assignment.update_attributes(is_active: false, end_on: end_on)
          end
        else
          puts "The benefit group assignment is already deactivated"
        end
      end
    rescue => e
      e.message
    end
  end
end
