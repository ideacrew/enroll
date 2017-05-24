require File.join(Rails.root, "lib/mongoid_migration_task")

class LinkEmployeesToEmployer < MongoidMigrationTask
  def migrate
    ce1 = CensusEmployee.find(ENV['ce1'].to_s)
    ce2 = CensusEmployee.find(ENV['ce2'].to_s)
    ce3 = CensusEmployee.find(ENV['ce3'].to_s)
    ce4 = CensusEmployee.find(ENV['ce4'].to_s)
    ce5 = CensusEmployee.find(ENV['ce5'].to_s)
    if ce1.present?
      ce1.link_employee_role!
    else
      raise "No Census Employee found for ce1"
    end
    if ce2.present?
      ce2.link_employee_role!
    else
      raise "No Census Employee found for ce2"
    end
    if ce3.present?
      ce3.link_employee_role!
    else
      raise "No Census Employee found for ce3"
    end
    if ce4.present?
      ce4.link_employee_role!
    else
      raise "No Census Employee found for ce4"
    end
    if ce5.present?
      ce5.link_employee_role!
    else
      raise "No Census Employee found for ce5"
    end
  end
end