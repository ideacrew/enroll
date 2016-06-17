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
end