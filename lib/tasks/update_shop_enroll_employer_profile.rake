namespace :update_shop do
  desc "Renewing employer benefit period"
  task :enroll_employer_profile => :environment do
    changed_count = 0

    effective_date = Date.new(2016,1,1)
    organizations = Organization.all_employers_by_plan_year_start_on(effective_date)

    employers = organizations.map(&:employer_profile).inject({}) do |employers, profile|
      employers[profile.fein] = profile.legal_name
      employers
    end
        
    employers.each do |fein, name|
      begin
        puts "Processing employer: #{name}"
        employer = EmployerProfile.find_by_fein(fein)
        if employer.blank?
          puts "  ** employer not found"
          next
        end

        renewal_factory = Factories::PlanYearEnrollFactory.new
        renewal_factory.employer_profile = employer
        renewal_factory.start_on = effective_date
        renewal_factory.enroll
        changed_count += 1
      rescue => e
        puts e.to_s
      end
    end

    puts "Processed #{employers.count} employers, renewed #{changed_count} employers"
  end

  task :cancel_benefit_group_assignment => :environment do 
    changed_count = 0

    effective_date = Date.new(2016,1,1)
    organizations = Organization.all_employers_by_plan_year_start_on(effective_date)

    employers = organizations.map(&:employer_profile).inject({}) do |employers, profile|
      employers[profile.fein] = profile.legal_name
      employers
    end

    employers.each do |fein, name|
      begin

        puts "Processing employer: #{name}"
        employer = EmployerProfile.find_by_fein(fein)
        if employer.blank?
          puts "  ** employer not found"
          next
        end

        next unless employer.active_plan_year.present?
        next unless employer.active_plan_year.start_on == effective_date

        published_plan_years = employer.plan_years.where(:"start_on" => effective_date).any_of([PlanYear.published.selector, PlanYear.renewing_published_state.selector])

        if published_plan_years.size == 0
          next
        end

        if published_plan_years.size > 1
          next
        end

        benefit_group_ids = employer.active_plan_year.benefit_groups.map(&:id) 

        count = 0
        found = 0

        employer.census_employees.each do |ce| 
          if ce.active_benefit_group_assignment.present? && !benefit_group_ids.include?(ce.active_benefit_group_assignment.benefit_group_id)
            ce.active_benefit_group_assignment.update_attributes(is_active: false)
          end
        end

        employer.census_employees.each do |ce| 
          if ce.is_active? && ce.active_benefit_group_assignment.blank?

            renewing_benefit_group_assignment = ce.benefit_group_assignments.renewing.detect{|bg_assignment|
              benefit_group_ids.include?(bg_assignment.benefit_group_id)
            }

            # TODO Handle cases where benefit group assignment shows coverage selected, while employee don't have coverage

            # if renewing_benefit_group_assignment.blank?
            #   renewing_benefit_group_assignment = ce.benefit_group_assignments.detect{ |bg_assignment| 
            #     benefit_group_ids.include?(bg_assignment.benefit_group_id) 
            #   }
            #   found += 1 if renewing_benefit_group_assignment.present?
            # end

            if renewing_benefit_group_assignment.blank?
              count += 1
            else 
              renewing_benefit_group_assignment.update_attributes(is_active: true)
            end
          end
        end

        puts "#{count} census employee records missing active benefit group assignments"
        # {found} mapped to #{effective_date.year} benefit group"
        changed_count += 1
      rescue => e
        puts e.to_s
      end
    end

    puts "Processed #{employers.count} employers, fixed #{changed_count} employers"
  end
end