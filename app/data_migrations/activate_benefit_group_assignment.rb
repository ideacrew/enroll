require File.join(Rails.root, "lib/mongoid_migration_task")

class ActivateBenefitGroupAssignment < MongoidMigrationTask
  def migrate
    action = ENV['action'].to_s
    case action
      when "update_benefit_group_assignment_for_er"
        update_benefit_group_assignment_for_er
      when "update_benefit_group_assignment_for_ce"
        update_benefit_group_assignment_for_ce
      else
        puts"The Action defined is not performed in the rake task" unless Rails.env.test?
    end
  end


  def update_benefit_group_assignment_for_ce
    begin
      census_employee = CensusEmployee.by_ssn(ENV['ce_ssn']).first
      if census_employee.nil?
        puts "No census employee was found with given ssn" unless Rails.env.test?
      else
        benefit_group_assignment=census_employee.benefit_group_assignments.where(id:ENV['bga_id']).first
        benefit_group_assignment.make_active
        puts "Activated Benefit Group Assignments for the Employee" unless Rails.env.test?
      end
    rescue => e
      e.message
    end
  end

  
  def update_benefit_group_assignment_for_er  
    begin
      benefit_package_id = ENV['benefit_package_id']      
      benefit_package = ::BenefitSponsors::BenefitPackages::BenefitPackage.find(benefit_package_id)
      if benefit_package.nil?
        puts "No Benefit Package was found with given id" unless Rails.env.test?
      else
        benefit_package.activate_benefit_group_assignments
        puts "Activated Benefit Group Assignments for the given Benefit Package" unless Rails.env.test?
      end
    rescue => e
      e.message
    end
  end
end