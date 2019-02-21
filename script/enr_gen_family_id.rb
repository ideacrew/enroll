@logger = Logger.new("#{Rails.root}/log/enrollment_notice_data_set.log")
@logger.info "Script Start #{TimeKeeper.datetime_of_record}"


@start_time = Date.new(2018,12,12,).in_time_zone('Eastern Time (US & Canada)').beginning_of_day
@end_time = Date.new(2018,12,12).in_time_zone('Eastern Time (US & Canada)').end_of_day
@fid = ""

if ARGV.size != 3
  exit!
else
  @fid = ARGV[0]
  puts "Family id: " + @fid
end

event_name = "enrollment_notice_with_date_range"

field_names = %w(
        primary_hbx_id
        primary_first_name
        primary_last_name
        hbx_enrollment_hbx_ids
      )

report_name = "#{Rails.root}/enrollment_notice_data_set.csv"

def valid_enrollment_hbx_ids(family)
  enrollment_hbx_ids= family.households.flat_map(&:hbx_enrollments).select do |hbx_en|
      (!hbx_en.is_shop?) && (!["coverage_canceled", "shopping", "inactive", "coverage_terminated"].include?(hbx_en.aasm_state)) &&
      (hbx_en.terminated_on.blank? || hbx_en.terminated_on >= TimeKeeper.date_of_record) &&
      (hbx_en.created_at >= @start_time && hbx_en.created_at <= @end_time)
    end.flat_map(&:hbx_id)
end

families = Family.where({
  "_id" => @fid,
  "households.hbx_enrollments" => {
    "$elemMatch" => {
      "kind" => "individual",
      "aasm_state" => { "$in" => HbxEnrollment::ENROLLED_STATUSES },
      "created_at" => { "$gte" => @start_time, "$lte" => @end_time }
      }
    }
  })

total_families = families.count
offset_count = 0
limit_count = 500
processed_count = 0

CSV.open(report_name, "w", force_quotes: true) do |csv|
  csv << field_names
  while (offset_count <= total_families) do
    families.offset(offset_count).limit(limit_count).each do |family|
      begin
        person = family.primary_applicant.person

        hbx_enrollment_hbx_ids = valid_enrollment_hbx_ids(family)
        hbx_enrollment_hbx_ids.compact!
        role = person.consumer_role

        if role.present? && hbx_enrollment_hbx_ids.present?

          puts "Processing for person with hbx_id: " + person.hbx_id

          event_kind = ApplicationEventKind.where(:event_name => event_name).first
          notice_trigger = event_kind.notice_triggers.first
          builder = notice_trigger.notice_builder.camelize.constantize.new(role, {
                    template: notice_trigger.notice_template,
                    subject: event_kind.title,
                    event_name: event_name,
                    options: {:hbx_enrollment_hbx_ids => hbx_enrollment_hbx_ids },
                    mpi_indicator: notice_trigger.mpi_indicator,
                    }.merge(notice_trigger.notice_trigger_element_group.notice_peferences)).deliver
          processed_count = processed_count + 1
          @logger.info "#{event_name} generated to family with primary_person: #{person.hbx_id}" unless Rails.env.test?

          csv << [
            person.hbx_id,
            person.first_name,
            person.last_name,
            hbx_enrollment_hbx_ids
          ]
        end
      rescue Exception => e
        @logger.error "Unable to deliver #{event_name} to family with PrimaryPerson: #{person.hbx_id} due to the following error #{e.backtrace}" unless Rails.env.test?
      end
    end
    @logger.info " #{offset_count} number of families processed at this point." unless Rails.env.test?
    offset_count = offset_count + limit_count
  end
  @logger.info "End of the script. #{processed_count} number of families processed." unless Rails.env.test?
end
