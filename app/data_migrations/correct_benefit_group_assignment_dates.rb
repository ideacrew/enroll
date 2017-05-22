require File.join(Rails.root, "lib/mongoid_migration_task")

class CorrectBenefitGroupAssignmentDates < MongoidMigrationTask  
  def migrate
    count = 0 
    Organization.exists(:employer_profile => true).each do |org|
      count += 1
      employer_profile = org.employer_profile

      if count % 10 == 0
        puts "processed #{count} employers"
      end

      employer_profile.census_employees.each do |census_employee|

        census_employee.benefit_group_assignments.each do |assignment|
          benefit_group = assignment.benefit_group
          next if benefit_group.blank?

          if !(benefit_group.start_on..benefit_group.end_on).cover?(assignment.start_on)
            assignment.update(start_on: benefit_group.start_on)
            puts "Fixed start date for #{census_employee.full_name}"
          end

          if assignment.end_on.present?
            if !(benefit_group.start_on..benefit_group.end_on).cover?(assignment.end_on) || assignment.end_on < assignment.start_on
              assignment.update(end_on: benefit_group.end_on)
              puts "Fixed end date for #{census_employee.full_name}"
            end
          end
        end
      end
    end
  end
end