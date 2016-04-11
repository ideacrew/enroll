namespace :migrations do
  desc "Change plan year plan selection for employer"
  task :change_plan_selection => :environment do
    plan_year = Organization.where(:legal_name => /The Arab Gulf States/i).first.employer_profile.active_plan_year
    benefit_group = plan_year.benefit_groups.first
    benefit_group.plan_option_kind = "single_carrier"
    benefit_group.elected_plans = benefit_group.elected_plans_by_option_kind
    benefit_group.save!
  end
end