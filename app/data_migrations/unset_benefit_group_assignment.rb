require File.join(Rails.root, "lib/mongoid_migration_task")

class UnsetBenefitGroupAssignment < MongoidMigrationTask
  def migrate
    begin
      census_employee = CensusEmployee.where(id:ENV['ce_id']).first
      if census_employee.nil?
        puts "No census employee was found with given id"
      else
        benefit_group_assignment = census_employee.benefit_group_assignments.where(id:ENV['bga_id']).first
        benefit_group_assignment.update_attributes(is_active: 'false')
      end
    rescue => e
      e.message
    end
  end
end
