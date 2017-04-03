require File.join(Rails.root, "lib/mongoid_migration_task")

class BuildShopEnrollment < MongoidMigrationTask
  def migrate
    begin
      people = Person.where(hbx_id: ENV['person_hbx_id'])
      if people.size !=1 
        puts "Check hbx_id. Found no (or) more than 1 persons" unless Rails.env.test?
        raise
      end
      person = people.first
      effective_on = Date.strptime(ENV['effective_on'].to_s, "%m/%d/%Y")
      plan_year_state = ENV['plan_year_state'].to_s
      new_hbx_id = ENV['new_hbx_id'].to_s

      benefit_group = person.active_employee_roles.first.employer_profile.plan_years.where(aasm_state: plan_year_state).first.default_benefit_group
      benefit_group ||= person.active_employee_roles.first.employer_profile.plan_years.where(aasm_state: plan_year_state).first.benefit_groups.first
      benefit_group_assignment = person.active_employee_roles.first.census_employee.benefit_group_assignments.where(benefit_group_id: benefit_group.id).first
      
      if benefit_group_assignment.nil?
        bga = BenefitGroupAssignment.new(benefit_group: benefit_group, start_on: benefit_group.start_on)
        bga.save!
      end
      
      enrollment = HbxEnrollment.new
      enrollment.kind = "employer_sponsored"
      enrollment.employee_role_id = person.active_employee_roles.first.id
      enrollment.enrollment_kind = "open_enrollment"
      enrollment.benefit_group_id = benefit_group.id
      enrollment.benefit_group_assignment_id = benefit_group_assignment.id
      enrollment.effective_on = effective_on
      enrollment.plan_id = benefit_group.reference_plan.id
      person.primary_family.active_household.hbx_enrollments << enrollment
      person.primary_family.active_household.save!
      enrollment.update_attributes(aasm_state: "coverage_selected")
      if new_hbx_id.present?
        enrollment.update_attributes!(hbx_id: new_hbx_id)
      end
      puts "Created a new shop enrollment with the given effective_on date" unless Rails.env.test?
    rescue => e
      puts "#{e}"
    end
  end
end
