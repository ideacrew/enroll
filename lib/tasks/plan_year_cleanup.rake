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

  desc "Cleanup plan years with invalid benefit groups"
  task :bad_plans_cleanup => :environment do 
    employers = {
      "Jons Cupcakes" => "123487348",
      "Native American Finance Officers Association" => "383419567",
      "Potomac River Capital, LLC" => "208375064"
    }

    begin


    bad_plan_ids = []

    reference_plan_ids = []
    employers.each do |employer_name, fein|
      employer = EmployerProfile.find_by_fein(fein)
      if employer
        employer.plan_years.each do |plan_year|
          reference_plan_ids << plan_year.benefit_groups.map(&:reference_plan_id)
        end
      end
    end

    bogus_plan_ids = reference_plan_ids.flatten.uniq.map(&:to_s).reject{|id| Plan.where(:id => id).any? }
    bogus_plan_ids = bogus_plan_ids.map{|bp| BSON::ObjectId.from_string(bp)}
 
    Organization.where("employer_profile.plan_years.benefit_groups.reference_plan_id" => {"$in" => bogus_plan_ids}).each do |organization|
      puts organization.legal_name
    end
    
    rescue => e
      puts e.to_s
    end
  end
end
