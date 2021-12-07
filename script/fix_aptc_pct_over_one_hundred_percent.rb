require 'csv'

report_name = "#{Rails.root}/enrollment_aptc_pct_list_#{TimeKeeper.date_of_record.strftime('%m_%d_%Y')}.csv"
field_names = %w(
        primary_hbx_id
        enrollment_hbx_id
        faulty_aptc_pct
        message
      )

CSV.open(report_name, "w", force_quotes: true) do |csv|
  csv << field_names

  affected_enrollments = HbxEnrollment.with_aptc.where(:created_at => {"$gte" => Date.new(2021,3,1)}).where(:elected_aptc_pct => {"$gt" => 1.0})
  affected_enrollments.each do |enrollment|
    affected_aptc = enrollment.elected_aptc_pct
    primary_hbx_id = enrollment&.family&.primary_family_member&.person&.hbx_id
    enrollment.update_attributes!(elected_aptc_pct: 1.0)
    if primary_hbx_id
      csv << [primary_hbx_id, enrollment.hbx_id, enrollment.elected_aptc_pct, "Enrollment with primary family member hbx_id #{primary_hbx_id} APTC % updated from #{affected_aptc} to 1.0"]
    else
      csv << ["", enrollment.hbx_id, enrollment.elected_aptc_pct, "Enrollment has no associated family or primary family member. APTC % updated, but no primary hbx id can be provided."]
    end
  end
end
