namespace :migrations do
  desc "Change plan year plan selection for employer"
  task :change_plan_selection => :environment do
    plan_year = Organization.where(:legal_name => /The Arab Gulf States/i).first.employer_profile.active_plan_year
    benefit_group = plan_year.benefit_groups.first
    benefit_group.plan_option_kind = "single_carrier"
    benefit_group.elected_plans = benefit_group.elected_plans_by_option_kind
    benefit_group.save!
  end

  desc "change renewed employer reference plan"
  task :change_renewed_employer_reference_plan => :environment do
    employer_profile = Organization.where(:legal_name => /The Memorial Foundation/i).first.employer_profile
    benefit_group = employer_profile.plan_years.where(:start_on => Date.new(2016, 4, 1)).first.benefit_groups.first
    new_reference_plan = Plan.where(:name => /BluePreferred PPO HSA\/HRA Silver 1500/i).first
    benefit_group.reference_plan= new_reference_plan
    benefit_group.elected_plans= [new_reference_plan]
    benefit_group.save!
    
    employer_profile.census_employees.each do |census_employee|
      bg_assignment = census_employee.active_benefit_group_assignment
      family = Family.where(:"households.hbx_enrollments.benefit_group_assignment_id" => bg_assignment._id).first
      active_enrollment = family.active_household.hbx_enrollments.where(:effective_on => Date.new(2016, 4, 1)).first
      new_enrollment = clone_enrollment(active_enrollment, family, new_reference_plan)
      new_enrollment.save!
      active_enrollment.cancel_coverage!
      new_enrollment.force_select_coverage!
      new_enrollment.begin_coverage!
    end
  end
end

def clone_enrollment_members(active_enrollment)
  hbx_enrollment_members = active_enrollment.hbx_enrollment_members
  hbx_enrollment_members.inject([]) do |members, hbx_enrollment_member|
    members << HbxEnrollmentMember.new({
      applicant_id: hbx_enrollment_member.applicant_id,
      eligibility_date: hbx_enrollment_member.eligibility_date,
      coverage_start_on: hbx_enrollment_member.coverage_start_on,
      is_subscriber: hbx_enrollment_member.is_subscriber
      })
  end
end

def clone_enrollment(active_enrollment, family, new_plan)
  new_enrollment = family.active_household.hbx_enrollments.new
  %w(coverage_household_id coverage_kind changing broker_agency_profile_id employee_role_id effective_on
    writing_agent_id original_application_type kind special_enrollment_period_id benefit_group_id benefit_group_assignment_id
    ).each do |attr|
    new_enrollment.send("#{attr}=", active_enrollment.send(attr))
  end
  new_enrollment.plan_id = new_plan._id
  new_enrollment.hbx_enrollment_members = clone_enrollment_members(active_enrollment)
  new_enrollment
end