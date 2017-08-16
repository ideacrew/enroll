require File.join(Rails.root, "lib/mongoid_migration_task")
class RemoveCongressCensusEmployee < MongoidMigrationTask
  def migrate
    begin
      ce = CensusEmployee.find(ENV['census_employee_id'])
      if ce.present?
        ce.delete
      else
        puts "Unable to find a Census Employee with ID provided."
      end
    end
  end
end