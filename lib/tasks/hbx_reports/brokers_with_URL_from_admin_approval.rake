#this rake task produces an csv report providing all brokers that have had a claim URL sent to them upon Admin Approval
require 'csv'

namespace :reports do
  namespace :shop do
    desc "All Brokers have had a claim URL sent to them upon Admin Approval"
    task :brokers => :environment do
      brokers = Person.exists(broker_role: true).broker_role_having_agency
      field_names  = %w(
          First_Name
          Last_Name
          Email
          NPN
          Date_of_Unique_URL_being_sent
          Unique_URL
        )

      processed_count = 0
      file_name = "#{Rails.root}/brokers_list_with_URL_from_admin_approval.csv"

      CSV.open(file_name, "w", force_quotes: true) do |csv|
        csv << field_names
        brokers.each do |broker|
          csv << [

              # First_Name
              # Last_Name
              # Email
              # NPN
              # Date_of_Unique_URL_being_sent
              # Unique_URL

              broker.broker_role.broker_agency_profile.try(:legal_name),
              broker.first_name,
              broker.last_name,
              broker.broker_role.email_address,
              broker.broker_role.npn,
              broker.broker_role.latest_transition_time,
              #broker.broker_role.broker_agency_profile.try(:accept_new_clients)]
              processed_count += 1
        end
      end

      puts "#{processed_count} Brokers to output file: #{file_name}"
    end
  end
end