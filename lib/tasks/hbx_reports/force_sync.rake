# frozen_string_literal: true

require 'rake'
require 'csv'
# The task to run is RAILS_ENV=production bundle exec rake reports:force_sync hbx_id="3382429"
# This rake generates a csv of all the hbx_ids greater than the input hbx id. Ex. 1000 => 1001, 1002, etc.
# The output csv is force_sync_report_DATE.csv

namespace :reports do
  desc 'List of hbx_ids greater than the input'
  task force_sync: :environment do
    hbx_id = ENV['hbx_id']
    processed_count = 0
    field_names = %w[HBX_ID Last_Name]
    date = TimeKeeper.date_of_record
    report_file_name = "#{Rails.root}/force_sync_report_#{date.strftime('%m_%d_%Y')}.csv"
    CSV.open(report_file_name, 'w', force_quotes: true) do |report_csv|
      report_csv << field_names
      people = Person.where(:hbx_id.gte => hbx_id)
      people.each do |person|
        report_csv << [person.hbx_id, person&.last_name]
        processed_count += 1
      end
      puts "processed #{processed_count} person records in report -- #{report_file_name}"
    end
  end
end