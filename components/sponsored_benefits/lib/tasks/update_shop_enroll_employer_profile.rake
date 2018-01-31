namespace :update_shop do
  desc "Renewing employer benefit period"
  task :enroll_employer_profile => :environment do
    changed_count = 0

    effective_date = Date.new(2015,12,1)
    organizations = Organization.all_employers_by_plan_year_start_on(effective_date)

    employers = organizations.map(&:employer_profile).inject({}) do |employers, profile|
      employers[profile.fein] = profile.legal_name
      employers
    end
        
    missing_family = 0
    missing_person = 0
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
        
        missing_family += renewal_factory.missing_family
        missing_person += renewal_factory.missing_person

        changed_count += 1
      rescue => e
        puts e.to_s
      end
    end

    puts "Processed #{employers.count} employers, renewed #{changed_count} employers"
    puts "Total missing families #{missing_family} missing person #{missing_person}"
  end


  task :waive_benefit_group_assignments => :environment do
    effective_date = Date.new(2016,1,1)
    organizations = Organization.all_employers_by_plan_year_start_on(effective_date)

    employers = organizations.map(&:employer_profile).inject({}) do |employers, profile|
      employers[profile.fein] = profile.legal_name
      employers
    end

    count = 0
    employers.each do |fein, name|
      begin

        puts "Processing employer: #{name}"
        employer = EmployerProfile.find_by_fein(fein)
        if employer.blank?
          puts "  ** employer not found"
          next
        end

        published_plan_years = employer.plan_years.where(:"start_on" => effective_date).any_of([PlanYear.published.selector, PlanYear.renewing_published_state.selector])

        if published_plan_years.size == 0
          next
        end

        if published_plan_years.size > 1
          next
        end

        next unless employer.active_plan_year.present?
        next unless employer.active_plan_year.start_on == effective_date
        benefit_group_ids = employer.active_plan_year.benefit_groups.map(&:id)

        created = 0
        waived = 0
        expired = 0

        employer.census_employees.each do |ce| 
          begin
            next unless ce.is_active?

            # Expire last year benefit group assignments
            ce.benefit_group_assignments.each do |bg_assignment|
              if bg_assignment.is_active? && !benefit_group_ids.include?(ce.active_benefit_group_assignment.benefit_group_id)
                bg_assignment.update_attributes(is_active: false, end_on: [employer.active_plan_year.start_on - 1.day, bg_assignment.start_on].max)
                bg_assignment.expire_coverage! if bg_assignment.may_expire_coverage?
                expired += 1
              end
            end

            renewal_factory = Factories::PlanYearEnrollFactory.new
            renewal_factory.employer_profile = employer
            renewal_factory.start_on = effective_date
            renewal_factory.benefit_group_ids = benefit_group_ids
            renewal_factory.end_on = employer.active_plan_year.end_on

            # Assign new benefit group assignment if active benefit group assignment missing
            if ce.active_benefit_group_assignment.blank?
              if ce.benefit_group_assignments.none? {|bg_assignment| benefit_group_ids.include?(bg_assignment.benefit_group_id)}
                ce.add_benefit_group_assignment(employer.active_plan_year.benefit_groups.first, effective_date)
                ce.active_benefit_group_assignment.update_attributes(is_active: true)
                created += 1
              end
            end

            # Waive benefit group assignment if coverage is waived for the employee
            if renewal_factory.waived_benefit_group_assignment(ce)
              waived += 1
            end
          rescue => e
            puts "#{e.to_s} occured for #{ce.full_name}"
          end
        end

        puts "#{expired} expired records,  #{created} created records, #{waived} waived records"
        count += 1
      rescue => e
        puts e.to_s
      end
    end

    puts "Processed #{employers.count} employers, updated #{count} employers"
  end
end