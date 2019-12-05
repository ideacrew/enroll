require File.join(Rails.root, "lib/mongoid_migration_task")

class ReinstateBenefitApplication < MongoidMigrationTask

  def migrate
    organizations = BenefitSponsors::Organizations::Organization.where(fein: ENV['fein'])
    benefit_application_start_on = Date.strptime(ENV['benefit_application_start_on'].to_s, "%m/%d/%Y")

    if organizations.size != 1
      puts "Found No (or) more than 1 organization with the given fein" unless Rails.env.test?
      return
    end

    benefit_application = organizations.first.employer_profile.benefit_applications.where(
      start_on: plan_year_start_on,
      aasm_state: "terminated"
    ).first

    BenefitSponsors::BenefitApplications::BenefitApplicationEnrollmentService(benefit_application).reinstate
  end
end
