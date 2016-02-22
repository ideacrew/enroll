namespace :migrations do
  desc "update eligibility for benefit groups"
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


  desc "fix 2015 employer benefit group eligibilities"
  task :update_employer_benefit_eligibility_rule => :environment do

    count = 0
    line = 0
    CSV.foreach("#{Rails.root.to_s}/ERs_with_doh_effective.csv") do |row|
      next if row[2] == 'FEIN'
      fein = row[2].gsub('-', '')

      Organization.where(fein: fein).each do |organization|
        employer_profile = organization.employer_profile
        published_plan_years = employer_profile.plan_years.any_of([PlanYear.published.selector, PlanYear.renewing_published_state.selector])
        published_plan_years.each do |plan_year|
          next if plan_year.start_on >= Date.new(2015,11,1)
          plan_year.benefit_groups.each do |benefit_group|
            if !(benefit_group.effective_on_kind == 'date_of_hire' && benefit_group.effective_on_offset == 0)
              puts "updating #{employer_profile.legal_name}"
              benefit_group.update_attributes(effective_on_kind: 'date_of_hire', effective_on_offset: 0)
              count += 1
            end
          end
        end
      end
    end

    puts "updated #{count} benefit groups of the employers"
  end

  desc "fix 2015 employer benefit group eligibilities"
  task :query_wrong_doh_employers => :environment do

    doh_feins = []
    CSV.foreach("#{Rails.root.to_s}/ERs_with_doh_effective.csv") do |row|
      next if row[2] == 'FEIN'  
      doh_feins << row[2].gsub('-', '')
    end

    Organization.exists(:employer_profile => true).each do |org|
      employer_profile = org.employer_profile
      if doh_feins.include?(employer_profile.fein)
        next
      end

      published_plan_years = employer_profile.plan_years.any_of([PlanYear.published.selector, PlanYear.renewing_published_state.selector])
      published_plan_years.each do |plan_year|
        next if plan_year.start_on >= Date.new(2015,11,1)
        plan_year.benefit_groups.each do |benefit_group|
          if benefit_group.effective_on_kind != 'first_of_month'
            puts "updating #{employer_profile.legal_name}"
            benefit_group.update_attributes(effective_on_kind: 'first_of_month')
          end
        end
      end
    end
  end
end