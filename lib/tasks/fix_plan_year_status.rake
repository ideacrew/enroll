require 'csv'

namespace :migrations do

  desc "Fix Plan Years based on CSV file"

  task :fix_plan_year_status => :environment do

    CSV.foreach("#{Rails.root}/FixPlanYears.csv", headers: true) do |row|
      date = (row['EffectiveDate'].to_date).strftime("%m/%d/%Y")
      if !EmployerProfile.find_by_fein(row['FEIN']).present?
        puts "employer not found #{row['FEIN']}" 
      else  
        if row["Term_or_Cancel?"].downcase == "cancelled"
          plan_year=EmployerProfile.find_by_fein(row['FEIN']).plan_years.where(start_on: date).first
            if plan_year.present? && plan_year.is_published?
              Rake::Task["migrations:cancel_employer_incorrect_renewal"].reenable
              Rake::Task["migrations:cancel_employer_incorrect_renewal"].invoke(row['FEIN']) unless Rails.env.test?
              puts "Plan Year Cancelled for #{row['ERLegalName']}" unless Rails.env.test?
            else
              Rake::Task["migrations:cancel_employer_renewal"].reenable
              Rake::Task["migrations:cancel_employer_renewal"].invoke(row['FEIN']) unless Rails.env.test?
              puts "Plan Year Cancelled for #{row['ERLegalName']}" unless Rails.env.test?
            end
        elsif row["Term_or_Cancel?"].downcase == "termination"
              Rake::Task["migrations:terminate_employer_account"].reenable
              Rake::Task["migrations:terminate_employer_account"].invoke(row['FEIN'],row['TerminationDate'],row['TerminationDate']) unless Rails.env.test?
              puts "Plan Year Terminated for #{row['ERLegalName']}" unless Rails.env.test?
        end
      end  
    end
  end
end