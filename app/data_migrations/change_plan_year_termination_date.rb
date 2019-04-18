
require File.join(Rails.root, "lib/mongoid_migration_task")

class ChangePlanYearTerminationDate < MongoidMigrationTask
  def migrate
    organizations = Organization.where(fein: ENV['fein'])
    plan_year_start_on = Date.strptime(ENV['plan_year_start_on'].to_s, "%m/%d/%Y")
    terminated_on = Date.strptime(ENV['new_terminated_on'].to_s, "%m/%d/%Y")
    if organizations.size != 1
      puts "Found No (or) more than 1 organization with the given fein" unless Rails.env.test?
      return
    end
    plan_year = organizations.first.employer_profile.plan_years.where(start_on: plan_year_start_on).first
    if plan_year.present? 
      begin
        if plan_year.aasm_state != "terminated"
          puts "Unable to update the termination date of plan year as the plan year is not in terminated state ." unless Rails.env.test?
        else
          plan_year.update_attributes!(end_on: terminated_on)
          plan_year.save
          puts "Update the termination date to #{new_terminated_on} ." unless Rails.env.test?
        end
      rescue Exception => e
        puts "Error: #{e.message}" unless Rails.env.test?
      end
    else
      puts "Unable to reinstate plan year/Plan Year not found." unless Rails.env.test?
    end
  end
end
