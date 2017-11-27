# Report: List of broker agencies with more than one broker
# Run: RAILS_ENV=production bundle exec rake reports:shop:broker_agencies_with_more_than_one_broker

require 'csv'

namespace :reports do

  namespace :shop do
    desc "Broker agencie's  account information"
    task :broker_agencies_with_more_than_one_broker => :environment do


      field_names  = %w(
          broker_agency_legal_name
          broker_agency_fein
          broker_agency_hbx_id
          brokers_count
        )
      processed_count = 0

      Dir.mkdir("hbx_report") unless File.exists?("hbx_report")
      file_name = "#{Rails.root}/hbx_report/broker_agency_with_more_than_one_broker.csv"

      CSV.open(file_name, "w", force_quotes: true, headers: true) do |csv|
        csv << field_names

        BrokerAgencyProfile.all.each do |profile|
          broker_count = profile.active_broker_roles.count
          if broker_count  > 1
            csv << [
                profile.organization.legal_name,
                profile.organization.fein,
                profile.organization.hbx_id,
                broker_count
            ]
          end
        end

        processed_count += 1
      end
      puts "List of all the brokers #{file_name}"
    end
  end
end