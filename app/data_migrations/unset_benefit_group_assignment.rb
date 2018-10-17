require File.join(Rails.root, "lib/mongoid_migration_task")

class UnsetBenefitGroupAssignment < MongoidMigrationTask

  def migrate
    census_employee = CensusEmployee.where(id:ENV['ce_id']).first
    if census_employee.present?
      bga = census_employee.benefit_group_assignments.last
      if bga.present?
        bga.update_attributes(is_active: 'false')
      else
        "No Benefit Group Assignment found for census employee" unless Rails.env.test?
      end
    else
      puts " No Census Employee Found." unless Rails.env.test?
    end
  end
end