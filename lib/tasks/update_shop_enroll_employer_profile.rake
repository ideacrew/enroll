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

        benefit_group_ids = employer.active_plan_year.benefit_groups.map(&:id) if employer.active_plan_year.present?
        
        employer.census_employees.each do |ce| 
          if ce.active_benefit_group_assignment.present? && !benefit_group_ids.include?(ce.active_benefit_group_assignment.benefit_group_id)
            ce.active_benefit_group_assignment.update_attributes(is_active: false)
          end
        end
      rescue => e
        puts e.to_s
      end
    end

  end
end