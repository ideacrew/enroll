# rails runner script/ivl_tax_cover_letter_notice.rb <file_name>, Example: rails runner script/ivl_tax_cover_letter_notice.rb 1095a_glue_data_set.csv -e production
file_1 = ARGV[0]

if !file_1.present?
  puts "Please enter a valid file_name as an argument. Example: rails runner script/ivl_tax_cover_letter_notice.rb 1095a_glue_data_set.csv"
  exit
end

begin
  csv_ea = CSV.open(file_1,"r",:headers =>true)
rescue Exception => e
  puts "Unable to open file #{e}"
end

@data_hash = {}
CSV.foreach(file_1,:headers =>true).each do |d|
  if @data_hash[d["Subscriber_HBX_ID"]].present?
    @data_hash[d["Subscriber_HBX_ID"]] << d
  else
    @data_hash[d["Subscriber_HBX_ID"]] = [d]
  end
end

field_names = %w(
        primary_hbx_id
        primary_first_name
        primary_last_name
        glue_aasm_state
        enrollment_hbx_id
        ea_enrollment_aasm_state
        ea_enr_effective_on
      )

file_2 = "#{Rails.root}/ivl_1095a_notice_report.csv"

event_kind = ApplicationEventKind.where(:event_name => 'ivl_tax_cover_letter_notice').first
notice_trigger = event_kind.notice_triggers.first

CSV.open(file_2, "w", force_quotes: true) do |csv|
  csv << field_names
  csv_ea.each do |row|
    person = Person.where(:hbx_id => row["Subscriber_HBX_ID"]).first
    enrollment = HbxEnrollment.by_hbx_id(row["Enrollment_Group_ID"]).first
    true_or_false = (row["Premium_Amount_Total"].present? && row["Premium_Amount_Total"] != "0.0") ? "true" : "false"

    if enrollment.present? && !enrollment.is_shop? && row["State"] != "canceled"
      consumer_role = person.consumer_role if person.present?
      if person.present? && consumer_role.present?
        begin
          builder = notice_trigger.notice_builder.camelize.constantize.new(consumer_role, {
                        template: notice_trigger.notice_template,
                        subject: event_kind.title,
                        event_name: 'ivl_tax_cover_letter_notice',
                        options: { :is_an_aqhp_hbx_enrollment=> true_or_false},
                        mpi_indicator: notice_trigger.mpi_indicator
                        }.merge(notice_trigger.notice_trigger_element_group.notice_peferences)
                        )
          builder.deliver

          csv << [
            person.hbx_id,
            person.first_name,
            person.last_name,
            row["State"],
            row["Enrollment_Group_ID"],
            enrollment.aasm_state,
            enrollment.effective_on.to_s
          ]
          puts "1095a Notice is sent to primary person with hbx_id: #{person.hbx_id}" unless Rails.env.test?
        rescue Exception => e
          puts "Unable to deliver to #{person.hbx_id} for the following error #{e.backtrace}" unless Rails.env.test?
        end
      else
        puts "No Person or No consumer role exists for hbx_id: #{person_hbx_id}" unless Rails.env.test?
      end
    end
  end
end