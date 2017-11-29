# Report: List of broker agencies with more than one broker
# Run: RAILS_ENV=production bundle exec rake reports:shop:broker_agencies_with_more_than_one_broker

require 'csv'

namespace :reports do

  namespace :shop do
    desc "Broker agencie's  account information"
    task :broker_agencies_with_more_than_one_broker => :environment do


      field_names  = %w(
          Broker Agency Legal Name
          Broker Agency FEIN
          Brokers count
        )

      file_name = "#{Rails.root}/hbx_report/broker_agency_with_more_than_one_broker.csv"

      CSV.open(file_name, "w", force_quotes: true, headers: true) do |csv|
        csv << field_names

        BrokerAgencyProfile.all.each do |profile|
          begin
            broker_count = profile.active_broker_roles.count
            if broker_count  > 1
              csv << [
                  profile.organization.legal_name,
                  profile.organization.fein,
                  broker_count
              ]
            end
          rescue e
            puts "Exception: #{e}"
          end
        end
      end
      puts "List of all the brokers #{file_name}"
    end
  end
end