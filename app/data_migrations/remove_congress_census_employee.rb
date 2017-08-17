require File.join(Rails.root, "lib/mongoid_migration_task")
class RemoveCongressCensusEmployee < MongoidMigrationTask
  def migrate
    begin
      ce = CensusEmployee.where(id:ENV['census_employee_id']).first
      if ce.present? && ce.employer_profile.active_plan_year.benefit_groups.any?{|bg| bg.is_congress}
        ce.delete
        puts "Census Employee was successfully removed."
      elsif ce.blank?
        puts "Unable to find a Census Employee with ID provided."
      elsif ce.present? && !ce.employer_profile.active_plan_year.benefit_groups.any?{|bg| bg.is_congress}
        puts "Census Employee is not a congress employee."
      end
    end
  end
end