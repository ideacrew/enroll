require 'csv'

report_name = "#{Rails.root}/enrollment_aptc_pct_list_#{TimeKeeper.date_of_record.strftime('%m_%d_%Y')}.csv"
field_names = %w(
        enrollment_hbx_id
        faulty_aptc_pct
        message
      )

CSV.open(report_name, "w", force_quotes: true) do |csv|
  csv << field_names

  affected_enrollments = HbxEnrollment.with_aptc.where(:created_at => {"$gte" => Date.new(2021,3,1)}).where(:elected_aptc_pct => {"$gt" => 1.0})
  affected_enrollments.each do |enrollment|
    enrollment.update_attributes!(elected_aptc_pct: 1.0)
    csv << [enrollment.hbx_id, enrollment.elected_aptc_pct, "Enrollment with hbx id #{enrollment.hbx_id} APTC % updated from #{enrollment.elected_aptc_pct} to 1.0"]
  end
end
