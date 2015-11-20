namespace :update_data do
  desc "Cleanup plan years with invalid benefit groups"
  task :plan_year_cleanup => :environment do 

    organizations = Organization.where("employer_profile.plan_years.benefit_groups.reference_plan_id" => {"$exists" => true, "$eq" => nil})
    puts "found #{organizations.count} employers with affected plan years"

    organizations.each do |organization|
      puts "processing...." + organization.legal_name

      begin
        employer = organization.employer_profile
        plan_years = employer.plan_years.select{|plan_year| plan_year.benefit_groups.map(&:reference_plan_id).include?(nil)}

        if plan_years.any?{ |py| py.published? }
          puts "#{organization.legal_name} has play year(under published state) which got affected."
          next
        end

        if plan_years.count > 1
          puts "#{organization.legal_name} has more than 1 play year which got affected."
          next
        end

        plan_years.each do |plan_year|
          benefit_group_ids = plan_year.benefit_groups.map(&:id)
          census_employees = CensusEmployee.by_benefit_group_ids(benefit_group_ids)

          if census_employees.any?
            puts "#{organization.legal_name} found #{census_employees.count} census_employees with invalid benefit group assignments"
            census_employees.each do |census_employee|
              census_employee.benefit_group_assignments.each do |bg_assignment| 
                if benefit_group_ids.include?(bg_assignment.benefit_group_id)
                  bg_assignment.delete
                end
              end
            end
          end

          plan_year.delete
        end
      rescue => e
        puts e.to_s
      end
    end
  end


  desc "Change plan year state to draft"
  task :update_plan_year_state_to_draft => :environment do 

    employers = {
      "Cullen Law Firm" => "522093298",
      "Capital Guidance" => "742112921",
      "Thunderbird Strategic LLC" => "473893217",
      "National Theatre Corporation" => "521014217"
    }

    employers.each do |employer_name, fein|
      employer = EmployerProfile.find_by_fein(fein)
      puts "processing #{employer.legal_name}..."
      if employer
        if employer.plan_years.count > 1
          puts "found #{employer.plan_years.count} on #{employer.legal_name}"
          next
        end
        employer.enrollment_denied! unless employer.applicant?
        plan_year = employer.plan_years.first
        plan_year.aasm_state = "draft"
        plan_year.save!
      else
        puts "unable to locate #{employer.legal_name}"
      end
    end
  end

  desc "Delete plan years with missing reference plans"
  task :delete_plan_years_with_missing_reference_plan  => :environment do 

    Organization.exists("employer_profile" => true).each do |organization|
      organization.employer_profile.plan_years.each do |plan_year|
        begin
          plan_year.benefit_groups.map(&:reference_plan)
        rescue Mongoid::Errors::DocumentNotFound => e
          puts "found #{organization.legal_name}"
          puts "processing #{organization.legal_name}...#{organization.employer_profile.fein}"
          if organization.employer_profile.plan_years.count > 1
            puts "#{organization.legal_name} have #{organization.employer_profile.plan_years.count} plan years"
            next
          end
          organization.employer_profile.plan_years.each do |plan_year|
            benefit_group_ids = plan_year.benefit_groups.map(&:id)
            census_employees = CensusEmployee.by_benefit_group_ids(benefit_group_ids)

            if census_employees.any?
              puts "#{organization.legal_name} found #{census_employees.count} census_employees with invalid benefit group assignments"
              census_employees.each do |census_employee|
                assignments = census_employee.benefit_group_assignments.reject{|bg_assignment| benefit_group_ids.include?(bg_assignment.benefit_group_id) }
                census_employee.benefit_group_assignments = assignments
                census_employee.save!
              end
            end

            plan_year.delete
          end
          puts "deleted plan year for #{organization.legal_name}..."
        end
      end
    end
  end
end
