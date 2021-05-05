# Run the following rake task: RAILS_ENV=production bundle exec rake paynow:click_tracking[start_date,end_date]
# # date_format: RAILS_ENV=production bundle exec rake paynow:click_tracking[%d/%m/%Y,%d/%m/%Y]
# # example: RAILS_ENV=production bundle exec rake paynow:click_tracking["01/01/2021","01/04/2021"]
require 'csv'
namespace :paynow do
  desc 'Track date and feature location of outgoing clicks on the pay now links'
  task :click_tracking, [:start_date, :end_date] => [:environment] do |task, args|

    file_name = "#{Rails.root}/public/pay_now_click_tracking.csv"
    field_names  = %w(
      source
      enrollment_id
      datetime_of_click
    )

    # PaymentTransaction model to be updated with a list of locations later, will need to update/read from that when implemented
    locations = ['plan_shopping', 'enrollment_tile']
    location_count = {}

    start_date = Date.strptime(args['start_date'],'%d/%m/%Y').to_date
    end_date   = Date.strptime(args['end_date'],'%d/%m/%Y').to_date

    if start_date > end_date
      puts "Exception: Start Date can not be after End Date."
      return
    end

    payment_transactions = PaymentTransaction.where(submitted_at: start_date..end_date)

    CSV.open(file_name, "w", force_quotes: true) do |row|
      row << field_names
      payment_transactions.each do |pt|
        begin
          row << [
            pt.source,
            pt.enrollment_id,
            pt.submitted_at
          ]

          if location_count[pt.source].present?
            location_count[pt.source] += 1
          else
            location_count[pt.source] = 1
          end
        rescue => e
          puts "check this enrollment: #{pt.enrollment_id}. Exception: #{e}"
        end
      end
    end

    puts "Total clicks: #{payment_transactions.count}"
    location_count.each_pair {|k,v| puts "Clicks from #{k}: #{v}"}
  end
end
