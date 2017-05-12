require File.join(Rails.root, "lib/mongoid_migration_task")

class GeneralAgencyAssignment < MongoidMigrationTask
  def migrate
    begin
      general_agency_profile = GeneralAgencyProfile.find(ENV['general_agency_id'])
      employer_profile = EmployerProfile.find(ENV['employer_profile_id'])
      broker_agency_profile = BrokerAgencyProfile.find(ENV['broker_agency_id'])
      open_enrollment_end_on = Date.strptime(ENV['open_enrollment_end_on'].to_s, "%m/%d/%Y")

      employer_profile.plan_years.first.update_attributes({open_enrollment_end_on: open_enrollment_end_on})

      broker_agency_profile_id = broker_agency_profile.primary_broker_role_id
      employer_profile.general_agency_accounts.build(general_agency_profile: general_agency_profile, start_on: TimeKeeper.datetime_of_record, broker_role_id: broker_agency_profile_id)

      employer_profile.save

      puts "GeneralAgencyProfile with id: #{ENV['general_agency_id']} is assigned to the given EmployerProfile with id: #{ENV['employer_profile_id']}" unless Rails.env.test?
    rescue Exception => e
      puts e.message unless Rails.env.test?
    end
  end
end
