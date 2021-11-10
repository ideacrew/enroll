# Run the following rake task: RAILS_ENV=production bundle exec rake paynow:click_tracking[start_date,end_date]
# # date_format: RAILS_ENV=production bundle exec rake paynow:click_tracking[%m/%d/%Y,%m/%d/%Y,test]
# # example: RAILS_ENV=production bundle exec rake paynow:click_tracking["01/01/2021","04/01/2021",'Test']

require 'csv'
namespace :paynow do
  desc 'Track date and feature location of outgoing clicks on the pay now links'
  task :click_tracking, [:start_date, :end_date, :carrier_abbrev] => [:environment] do |task, args|
    file_name = "#{Rails.root}/public/pay_now_click_tracking.csv"
    field_names  = %w(
      source
      enrollment_id
      datetime_of_click
      hbx_id
    )

    # PaymentTransaction model to be updated with a list of locations later, will need to update/read from that when implemented
    location_count = {}
    carrier_list = EnrollRegistry[:carrier_abbev_list].feature.item

    start_date = Date.strptime(args['start_date'],'%m/%d/%Y').to_date
    end_date   = Date.strptime(args['end_date'],'%m/%d/%Y').to_date

    if start_date > end_date
      puts "Exception: Start Date can not be after End Date."
      return
    end

    if args['carrier_abbrev'].nil? || !carrier_list.include?(args['carrier_abbrev'])
      puts "Exception: Issue with Carrier Name"
      return
    end

    carrier = BenefitSponsors::Organizations::IssuerProfile.find_by_abbrev(args['carrier_abbrev'])

    unless carrier.present?
      puts "carrier profile was not found"
      return
    end

    payment_transactions = PaymentTransaction.where(submitted_at: start_date.beginning_of_day..end_date.end_of_day, carrier_id: carrier.id.to_s)

    CSV.open(file_name, "w", force_quotes: true) do |row|
      row << field_names
      payment_transactions.each do |pt|
        begin
          enrollment_hbx_id = HbxEnrollment.find(pt.enrollment_id.to_s)&.hbx_id
          row << [
            pt.source,
            pt.enrollment_id,
            pt.submitted_at,
            enrollment_hbx_id
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