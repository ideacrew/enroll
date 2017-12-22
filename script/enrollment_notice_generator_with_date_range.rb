@logger = Logger.new("#{Rails.root}/log/enrollment_notice_data_set.log")
@logger.info "Script Start #{TimeKeeper.datetime_of_record}"

@end_date = Date.new(2017, 12, 20)
@start_date = Date.new(2017, 11, 1)

event_name = "enrollment_notice_with_date_range"

field_names = %w(
        primary_hbx_id
        primary_first_name
        primary_last_name
      )

report_name = "#{Rails.root}/enrollment_notice_data_set.csv"

#Check if any of the Enrolled Enrollment was an Auto Renewing Enrollment
def any_enrollment_was_in_renewal_status?(enrollments)
  enrollments.any?{ |hbx_enr| hbx_enr.was_in_renewal_status? }
end

def valid_enrollment_hbx_ids(family)
  enrollments = family.enrollments
  good_enrollments = enrollments.where(kind: "individual").enrolled.by_submitted_datetime_range(@start_date, @end_date)
  auto_renewing_enrollments = enrollments.where(kind: "individual").enrolled.by_submitted_datetime_range(@start_date, @end_date).where(:aasm_state.in => HbxEnrollment::RENEWAL_STATUSES )
  bad_enrollments_fre = enrollments.where(kind: "individual").by_submitted_datetime_range(Date.new(2017, 1, 1), @start_date - 1.days).where(:aasm_state.in => HbxEnrollment::ENROLLED_STATUSES )

  good_enrollments.uniq!

  if !bad_enrollments_fre.present? && !any_enrollment_was_in_renewal_status?(enrollments) && !auto_renewing_enrollments.present?
    return good_enrollments.map(&:hbx_id)
  else
    return []
  end
end

families = Family.where({
  "households.hbx_enrollments" => {
    "$elemMatch" => {
      "kind" => "individual",
      "submitted_at" => {:"$gte" => @start_date, :"$lte" => @end_date},
      "aasm_state" => { "$in" =>  HbxEnrollment::ENROLLED_STATUSES }
    }
  }
})

CSV.open(report_name, "w", force_quotes: true) do |csv|
  csv << field_names
  families.each do |family|
    begin
      person = family.primary_applicant.person

      hbx_enrollment_hbx_ids = valid_enrollment_hbx_ids(family)
      hbx_enrollment_hbx_ids.compact!

      if hbx_enrollment_hbx_ids.present?
        IvlNoticesNotifierJob.perform_later(person.id.to_s, event_name, {:hbx_enrollment_hbx_ids => hbx_enrollment_hbx_ids }) if person.consumer_role.present?
        @logger.info "#{event_name} generated to family with primary_person: #{person.hbx_id}" unless Rails.env.test?
        csv << [
          person.hbx_id,
          person.first_name,
          person.last_name
        ]
      end
    rescue Exception => e
      @logger.error "Unable to deliver #{event_name} to family with PrimaryPerson: #{person.hbx_id} due to the following error #{e.backtrace}" unless Rails.env.test?
    end
  end
  @logger.info "End of the scirpt" unless Rails.env.test?
end
