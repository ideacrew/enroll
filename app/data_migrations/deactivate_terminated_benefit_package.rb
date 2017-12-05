
require File.join(Rails.root, "lib/mongoid_migration_task")

class DeactivateTerminatedBenefitPackage < MongoidMigrationTask

  def migrate
    CensusEmployee.where("benefit_group_assignments.aasm_state" => "coverage_terminated").each do |ce|
      ce.benefit_group_assignments.each do |benefit_group_assignment|
      benefit_group_assignment.deactivate_terminated_coverage
      end
    end
  end

end