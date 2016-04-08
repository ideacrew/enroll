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
  end
end