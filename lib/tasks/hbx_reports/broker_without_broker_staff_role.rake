# Report for brokers without broker staff role.
# rake command: RAILS_ENV=production bundle exec rake reports:broker_without_staff_role

require 'csv'

namespace :reports do

  desc "Broker Without Broker Staff Role"
  task :broker_without_staff_role => :environment do

    people = Person.broker_role_certified.where("user" => {"$exists" => true}, "broker_agency_staff_roles" => {"$exists" => false})
    field_names  = %w(
        Person_Hbx_id
        Broker_Role
        Broker_Staff_Role
        Broker_Agency_Name
        Broker_Agency_Npn
        Broker_Fein
      )

    processed_count = 0
    file_name = "#{Rails.root}/broker_without_staff_role_list_#{TimeKeeper.date_of_record.strftime("%m_%d_%Y")}.csv"

    CSV.open(file_name, "w", force_quotes: true) do |csv|
      csv << field_names

      people.each do |person|
        csv << [
            person.hbx_id,
            person.broker_role.present?,
            person.broker_agency_staff_roles.detect{ |staff| staff.broker_agency_profile_id == person.broker_role.broker_agency_profile_id }.present?,
            person.broker_role.broker_agency_profile.legal_name,
            person.broker_role.npn,
            person.broker_role.broker_agency_profile.fein
            ]
        processed_count += 1
      end
    end
    puts "Total people with broker role and with out staff_role #{processed_count}, report to output file: #{file_name}"
  end
end