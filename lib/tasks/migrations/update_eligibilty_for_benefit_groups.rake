namespace :migrations do
  desc "create missing consumer roles for dependents"
  task :update_eligibility_for_benefit_groups => :environment do
    organizations = Organization.where(:"employer_profile.plan_years.start_on".gte => Date.new(2015,11,1))
    count = 0
    organizations.each do |org|
      employer = org.employer_profile
      published_plan_years = employer.plan_years.any_of([PlanYear.published.selector, PlanYear.renewing_published_state.selector])
      published_plan_years.each do |plan_year|
        next if plan_year.start_on < Date.new(2015,11,1)
        plan_year.benefit_groups.each do |benefit_group|
          if benefit_group.effective_on_kind == 'date_of_hire'
            count += 1
            benefit_group.update_attributes(effective_on_kind: 'first_of_month')
          end
        end
      end
    end
    puts "updated #{count} benefit groups"
  end
end