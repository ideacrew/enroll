# rails runner script/final_catastrophic_notice.rb <file_name>, Example: rails runner script/final_catastrophic_notice.rb cat_plans_glue_data_set.csv
file_1 = ARGV[0]

begin
  csv_ea = CSV.open(file_1,"r",:headers =>true)
rescue Exception => e
  puts "Unable to open file #{e}"
end

field_names = %w(
        primary_hbx_id
        primary_first_name
        primary_last_name
      )

file_2 = "#{Rails.root}/public/ivl_catastrophic_notice_report.csv"

event_kind = ApplicationEventKind.where(:event_name => 'final_catastrophic_plan_2016').first
notice_trigger = event_kind.notice_triggers.first

CSV.open(file_2, "w", force_quotes: true) do |csv|
  csv << field_names
  csv_ea.each do |row|
    person = Person.where(:hbx_id => row["Subscriber_HBX_ID"]).first
    consumer_role = person.consumer_role if person.present?
    if person.present? && consumer_role.present?
      begin
        builder = notice_trigger.notice_builder.camelize.constantize.new(consumer_role, {
                      template: notice_trigger.notice_template,
                      subject: event_kind.title,
                      event_name: 'final_catastrophic_plan_2016',
                      mpi_indicator: notice_trigger.mpi_indicator
                      }.merge(notice_trigger.notice_trigger_element_group.notice_peferences)
                      )
        builder.deliver

        csv << [
          person.hbx_id,
          person.first_name,
          person.last_name
        ]
      rescue Exception => e
        puts "Unable to deliver to #{person.hbx_id} for the following error #{e.backtrace}"
      end
    else
      puts "No Person exists or No consumer role exists for hbx_id: #{row["Subscriber_HBX_ID"]}."
    end
  end
end
