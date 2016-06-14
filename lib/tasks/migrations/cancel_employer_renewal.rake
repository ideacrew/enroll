namespace :migrations do

  desc "Cancel renewal for employer"
  task :cancel_employer_renewal, [:fein] => [:environment] do |task, args|
    
    employer_profile = EmployerProfile.find_by_fein(args[:fein])

    if employer_profile.blank?
      puts "employer profile not found!"
      return
    end

    if renewing_plan_year = employer_profile.plan_years.renewing.first
      puts "canceling renewal for employer #{employer_profile.legal_name}"

      employer_profile.census_employees.each do |census_employee|
        census_employee.renewal_benefit_group_assignment.delete
      end

      renewing_plan_year.cancel_renewal!
      puts "cancellation successful!"
    else
      puts "renewing plan year not found!!"
    end
  end

  desc "Cancel incorrect renewal for employer"
  task :cancel_employer_incorrect_renewal, [:fein, :plan_year_start_on] => [:environment] do |task, args|
    
    employer_profile = EmployerProfile.find_by_fein(args[:fein])

    if employer_profile.blank?
      puts "employer profile not found!"
      exit
    end

    plan_year_start_on = Date.strptime(args[:plan_year_start_on], "%m/%d/%Y")

    if plan_year = employer_profile.plan_years.where(:start_on => plan_year_start_on).published.first
        enrollments = enrollments_for_plan_year(plan_year)
        if enrollments.any?
          puts "Canceling employees coverage for employer #{organization.legal_name}"
        end

        enrollments.each do |hbx_enrollment|
          if hbx_enrollment.may_cancel_coverage?
            hbx_enrollment.cancel_coverage!
            # Just make sure cancel propograted
          end
        end

      puts "canceling plan year for employer #{employer_profile.legal_name}"
      plan_year.cancel!
      puts "cancellation successful!"
    else
      puts "renewing plan year not found!!"
    end
  end
end


