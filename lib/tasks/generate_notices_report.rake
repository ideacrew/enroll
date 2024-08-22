# frozen_string_literal: true

desc "Task to generate notices report"
# Example rake command with start and end dates:
# rake generate_notices_report start_date="01/01/2021" end_date="01/31/2021"
task :generate_notices_report => :environment do
  start_date = ENV['start_date'] || TimeKeeper.date_of_record.beginning_of_day
  end_date = ENV['end_date'] || TimeKeeper.date_of_record.end_of_day

  log "Beginning notices report process for #{start_date} to #{end_date}"

  result = Operations::Reports::GenerateNoticesReport.new.call({start_date: start_date, end_date: end_date})

  log "Notices report process completed with status: #{result.success? ? 'Success' : 'Failure'}"
end
