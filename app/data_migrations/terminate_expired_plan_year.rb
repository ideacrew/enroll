require File.join(Rails.root, "lib/mongoid_migration_task")

class TerminateExpiredPlanYear< MongoidMigrationTask
  def migrate
    plan_year_start_on = Date.strptime(ENV['plan_year_start_on'].to_s, "%m/%d/%Y")
    organization = Organization.where(fein: ENV['fein']).first
    end_on = Date.strptime(ENV['expected_end_on'].to_s, "%m/%d/%Y")
    terminate_on = Date.strptime(ENV['expected_termination_date'].to_s, "%m/%d/%Y")
    if organization.nil?
      puts "no organization was found with given #{ENV['fein']}"
      raise 'no employer found with given fein'
    end
    target_plan_years= organization.employer_profile.plan_years.where(start_on:plan_year_start_on, aasm_state: "expired")
    if target_plan_years.size <1 
      puts "no organization was found with given #{ENV['fein']} has expired plan year start on #{ENV['plan_year_start_on']} "
    else 
      target_plan_years.each do |plan_year| 
        if plan_year.may_terminate?
          plan_year.terminate!(end_on)
          plan_year.update_attributes!(end_on: end_on, :terminated_on => terminate_on)
          bg_ids = plan_year.benefit_groups.map(&:id)
          census_employees = CensusEmployee.where({ :"benefit_group_assignments.benefit_group_id".in => bg_ids })
          census_employees.each do |census_employee|
           census_employee.benefit_group_assignments.where(:benefit_group_id.in => bg_ids).each do |assignment|
              assignment.update(end_on: plan_year.end_on) if assignment.end_on.present? && assignment.end_on > plan_year.end_on     
           end 
          end 
          enrollments = enrollments_for_plan_year(plan_year)
          enrollments.each do |hbx_enrollment|
            if hbx_enrollment.may_terminate_coverage?
              hbx_enrollment.terminate_coverage!
              hbx_enrollment.update_attributes!(terminated_on: end_on, termination_submitted_on: terminate_on)
            end
          end
        end
      end
    end
    
  def enrollments_for_plan_year(plan_year)
    id_list = plan_year.benefit_groups.map(&:id)
    families = Family.where(:"households.hbx_enrollments.benefit_group_id".in => id_list)
    enrollments = families.inject([]) do |enrollments, family|
      enrollments += family.active_household.hbx_enrollments.where(:benefit_group_id.in => id_list).any_of([HbxEnrollment::enrolled.selector, HbxEnrollment::renewing.selector]).to_a
    end
  end
  end
end









