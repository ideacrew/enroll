require File.join(Rails.root, "lib/mongoid_migration_task")

class CorrectPlanYearEndDate < MongoidMigrationTask
  def migrate
    begin
      organization = BenefitSponsors::Organizations::Organization.where(fein: ENV['fein']).first
      puts "No Oganization found" if  organization.blank? && !(Rails.env.test?)

      start_on = Date.strptime(ENV['py_effective_on'].to_s, "%m/%d/%Y")
      benefit_application = organization.employer_profile.benefit_applications.where(:"effective_period.min" => start_on).first
      puts "No Benefit Application found" if benefit_application.blank? && !(Rails.env.test?)
      new_end_date = (start_on + 1.year) - 1.day

      benefit_application.update_attributes(effective_period: start_on..new_end_date)
      puts "Updated Benefit Application end date" unless Rails.env.test?
    rescue Exception => e
      puts e.message
    end
  end
end
