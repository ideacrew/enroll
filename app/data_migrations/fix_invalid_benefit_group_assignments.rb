require File.join(Rails.root, "lib/mongoid_migration_task")

class FixInvalidBenefitGroupAssignments < MongoidMigrationTask

  def migrate
    Organization.exists(:employer_profile => true).no_timeout.each do |org|
      employer_profile = org.employer_profile
      puts "Processing #{org.legal_name}" unless Rails.env.test?

      count = 0
      employer_profile.census_employees.non_terminated.no_timeout.each do |census_employee|

        count += 1
        if count % 10 == 0
          puts "processed #{count} census_employees under #{employer_profile.legal_name}" unless Rails.env.test?
        end

        census_employee.benefit_group_assignments.each do |assignment|
          next if assignment.valid?
          puts assignment.errors.messages.to_s +  " -- #{census_employee.full_name}" unless Rails.env.test?

          if assignment.errors.messages[:end_on].present?
            if assignment.errors.messages[:end_on].include?("can't occur before start date")
              assignment.end_on = assignment.benefit_group.end_on
              assignment.save(:validate => false)
            end
          end
        end

        active_plan_year = employer_profile.active_plan_year
        if active_plan_year.present?
          bg_ids = active_plan_year.benefit_groups.pluck(:_id)

          census_employee.benefit_group_assignments.where(:benefit_group_id.nin => bg_ids, :is_active => true).each do |assignment|
            assignment.update(is_active: false)
            puts "Fixed default assignment for CE: #{census_employee.full_name}" unless Rails.env.test?
          end

          if census_employee.active_benefit_group_assignment.blank?
            census_employee.find_or_create_benefit_group_assignment(active_plan_year.benefit_groups)
          end
        end
      end
    end
  end
end
