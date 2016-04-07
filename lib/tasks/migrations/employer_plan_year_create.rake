namespace :migrations do
  desc "create employer plan year"
  task :employer_plan_year_create => :environment do

    plan_year_create = Proc.new do |organization|
      puts "Processing #{organization.legal_name}"
      employer_profile = organization.employer_profile
      prev_plan_year = employer_profile.plan_years.published.first

      new_plan_year = employer_profile.plan_years.build({
        start_on: Date.new(2015, 11, 1),
        end_on: Date.new(2015, 11, 1) + 1.year - 1.day,
        open_enrollment_start_on: Date.new(2015, 10, 1),
        open_enrollment_end_on: Date.new(2015, 10, 10),
        fte_count: prev_plan_year.fte_count,
        pte_count: prev_plan_year.pte_count,
        msp_count: prev_plan_year.msp_count
      })

      new_plan_year.save!
      new_plan_year.update_attributes({:aasm_state => 'active'})
      add_benefit_groups(prev_plan_year, new_plan_year, employer_profile)
    end
    
    plan_year_create.call Organization.where(:legal_name => 'ACE').first
    plan_year_create.call Organization.where(:legal_name => /JSP Companies/i).first
    plan_year_create.call Organization.where(:legal_name => /Colapinto LLP/i).first
    plan_year_create.call Organization.where(:legal_name => /Preventive Measures of/i).first


    new_plan_year_create = Proc.new do |organization|
      puts "Processing #{organization.legal_name}"

      employer_profile = organization.employer_profile
      new_plan_year = employer_profile.plan_years.build({
        start_on: Date.new(2015, 11, 1),
        end_on: Date.new(2015, 11, 1) + 1.year - 1.day,
        open_enrollment_start_on: Date.new(2015, 10, 1),
        open_enrollment_end_on: Date.new(2015, 10, 10)
      })

      new_plan_year.save!
    end

    new_plan_year_create.call Organization.where(:legal_name => /Civic Nation/i).first
    new_plan_year_create.call Organization.where(:legal_name => /Association of Proposal Management Professionals/i).first
  end
end

def add_benefit_groups(active_plan_year, new_plan_year, employer_profile)
  active_plan_year.benefit_groups.each do |active_group|

    index = active_plan_year.benefit_groups.index(active_group) + 1
    new_year = active_plan_year.start_on.year + 1

    reference_plan_id = Plan.find(active_group.reference_plan_id).renewal_plan_id
    if reference_plan_id.blank?
      raise PlanYearRenewalFactoryError, "Unable to find renewal for referenence plan: Id #{active_group.reference_plan.id} Year #{active_group.reference_plan.active_year} Hios #{active_group.reference_plan.hios_id}"
    end

    elected_plan_ids = reference_plan_ids(active_group)
    if elected_plan_ids.blank?
      raise PlanYearRenewalFactoryError, "Unable to find renewal for elected plans: #{active_group.elected_plan_ids}"
    end

    new_group = new_plan_year.benefit_groups.build({
      title: "#{active_group.title} (#{new_year})",
      effective_on_kind: "first_of_month",
      terminate_on_kind: active_group.terminate_on_kind,
      plan_option_kind: active_group.plan_option_kind,
      default: active_group.default,
      effective_on_offset: active_group.effective_on_offset,
      employer_max_amt_in_cents: active_group.employer_max_amt_in_cents,
      relationship_benefits: active_group.relationship_benefits,
      reference_plan_id: reference_plan_id,
      elected_plan_ids: elected_plan_ids,
      is_congress: false
      })

    if new_group.save
      update_census_employees(new_group, employer_profile)
    else
      raise "Error saving benefit_group"
    end
  end
end

def reference_plan_ids(active_group)
  start_on_year = (active_group.start_on + 1.year).year
  if active_group.plan_option_kind == "single_carrier"
    Plan.by_active_year(start_on_year).shop_market.health_coverage.by_carrier_profile(active_group.reference_plan.carrier_profile).and(hios_id: /-01/).map(&:id)
  elsif active_group.plan_option_kind == "metal_level"
    Plan.by_active_year(start_on_year).shop_market.health_coverage.by_metal_level(active_group.reference_plan.metal_level).and(hios_id: /-01/).map(&:id)
  else
    Plan.where(:id.in => active_group.elected_plan_ids).map(&:renewal_plan_id)
  end
end

def update_census_employees(new_group, employer_profile)
  employer_profile.census_employees.active.each do |census_employee|

    census_employee.benefit_group_assignments.select { |assignment| assignment.is_active? }.each do |benefit_group_assignment|
      benefit_group_assignment.end_on = [new_group.start_on - 1.day, benefit_group_assignment.start_on].max
      benefit_group_assignment.update_attributes(is_active: false)
    end

    census_employee.benefit_group_assignments << BenefitGroupAssignment.new(benefit_group: new_group, start_on: new_group.start_on, is_active: true)

    unless census_employee.active_benefit_group_assignment.save
      raise "unable to save census_employee"
    end
  end
end