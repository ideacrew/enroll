require File.join(Rails.root, "lib/mongoid_migration_task")

class ResolveCensusEmployeeValidationFailures < MongoidMigrationTask

  def create_new_benefit_group_assignment(employee, benefit_group)
    assignment = employee.benefit_group_assignments.build(benefit_group: benefit_group, start_on: benefit_group.start_on)
    assignment.save

    if (PlanYear::PUBLISHED + PlanYear::RENEWING_PUBLISHED_STATE).include?(benefit_group.plan_year.aasm_state)
      assignment.make_active
    end

    assignment
  end

  def fix_enrollment_benefit_group_assignments(enrollment)
    benefit_group = enrollment.benefit_group
    enrollments = enrollment.family.active_household.hbx_enrollments.shop_market.where(:aasm_state.nin => ['shopping', 'coverage_canceld'])
    
    # Fix enrollment benefit group assignment
    enrollments.each do |enrollment|
      if enrollment.benefit_group_id != enrollment.benefit_group_assignment.benefit_group_id
        employee = enrollment.benefit_group_assignment.census_employee
        new_assignment = employee.benefit_group_assignments.where(:benefit_group_id => enrollment.benefit_group_id).first
        new_assignment = create_new_benefit_group_assignment(employee, benefit_group) if new_assignment.blank?
        enrollment.update(benefit_group_assignment_id: new_assignment.id)
        puts "Updated benefit group assignment for HbxId: #{enrollment.hbx_id}" unless Rails.env.test?
      end
    end
  end

  def migrate
    Organization.exists(:employer_profile => true).each do |org|

      employer_profile = org.employer_profile
      active_plan_year = employer_profile.active_plan_year
      next if active_plan_year.blank?

      puts "Processing #{org.legal_name}" unless Rails.env.test?

      count = 0
      employer_profile.census_employees.non_terminated.each do |census_employee|

        count += 1
        if count % 10 == 0
          puts "processed #{count} census_employees"
        end

        census_employee.benefit_group_assignments.each do |assignment|
          next if assignment.valid?
          puts assignment.errors.messages.to_s +  " -- #{census_employee.id}" unless Rails.env.test?

          if assignment.errors.messages[:hbx_enrollment].present?
            if assignment.errors.messages[:hbx_enrollment].include?("hbx_enrollment required")
              assignment.delink_coverage! if assignment.may_delink_coverage?
              assignment.update(hbx_enrollment_id: nil)
            else
              enrollment = assignment.hbx_enrollment
              fix_enrollment_benefit_group_assignments(enrollment)

              if assignment.hbx_enrollment_id.present?
                assignment.hbx_enrollment_id = nil
                assignment.save(:validate => false)
                assignment.reload

                enrollment = assignment.hbx_enrollment
                assignment.update(hbx_enrollment_id: enrollment.id)
              end
            end
          end
        end

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
