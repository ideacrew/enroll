# rails runner script/final_catastrophic_notice.rb <file_name>, Example: rails runner script/final_catastrophic_notice.rb cat_plans_glue_data_set.csv
file_1 = ARGV[0]

if !file_1.present?
  puts "Please enter a valid file_name as an argument. Example: rails runner script/final_catastrophic_notice.rb cat_plans_glue_data_set.csv"
  exit
end

begin
  csv_ea = CSV.open(file_1,"r",:headers =>true)
rescue Exception => e
  puts "Unable to open file #{e}"
end

field_names = %w(
        primary_hbx_id
        primary_first_name
        primary_last_name
        consumer
        employee
        enrollment_kind
        ea_enrollment_metal_level
        ea_enrollment_market_kind
        ea_enrollment_state
        ea_enrollment_effective_on
      )

file_2 = "#{Rails.root}/public/ivl_catastrophic_notice_report.csv"

event_kind = ApplicationEventKind.where(:event_name => 'final_catastrophic_plan').first
notice_trigger = event_kind.notice_triggers.first

CSV.open(file_2, "w", force_quotes: true) do |csv|
  csv << field_names
  csv_ea.each do |row|
    next if row["State"] == "canceled"
    hbx_enrollment = HbxEnrollment.by_hbx_id(row["Enrollment_Group_ID"]).first
    person = Person.where(:hbx_id => row["Subscriber_HBX_ID"]).first
    consumer_role = person.consumer_role if person.present?
    if person.present? && consumer_role.present? && hbx_enrollment.present? && hbx_enrollment.plan_id.present?
      begin
        builder = notice_trigger.notice_builder.camelize.constantize.new(consumer_role, {
                      template: notice_trigger.notice_template,
                      subject: event_kind.title,
                      event_name: 'final_catastrophic_plan',
                      mpi_indicator: notice_trigger.mpi_indicator
                      }.merge(notice_trigger.notice_trigger_element_group.notice_peferences)
                      )
        builder.deliver

        csv << [
          person.hbx_id,
          person.first_name,
          person.last_name,
          person.has_active_consumer_role?,
          person.has_active_employee_role?,
          hbx_enrollment.kind,
          hbx_enrollment.plan.metal_level,
          hbx_enrollment.aasm_state,
          hbx_enrollment.effective_on.to_s
        ]
      rescue Exception => e
        puts "Unable to deliver to #{person.hbx_id} for the following error #{e.backtrace}"
      end
    else
      puts "No Person or No consumer role or No enrollment exists for hbx_id: #{row["Subscriber_HBX_ID"]} and enrollment_hbx_id: #{row["Enrollment_Group_ID"]}."
    end
  end
end
