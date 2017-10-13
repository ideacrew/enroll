class ShopEmployeeNotices::EmployeeDependentAgeOffTermination < ShopEmployeeNotice

  attr_accessor :census_employee, :dep_hbx_ids

  def initialize(census_employee, args = {})
    self.dep_hbx_ids = args[:options][:dep_hbx_ids]
    super(census_employee, args)
  end

  def deliver
    build
    append_data
    generate_pdf_notice
    non_discrimination_attachment
    attach_envelope
    upload_and_send_secure_message
    send_generic_notice_alert
  end

  def append_data
    now = TimeKeeper.date_of_record
    hbx = HbxProfile.current_hbx
    bc_period = hbx.benefit_sponsorship.benefit_coverage_periods.detect { |bcp| bcp if (bcp.start_on..bcp.end_on).cover?(now.next_year) }
    names = []
    if bc_period.present?
      self.dep_hbx_ids.each do |dep_id|
        names << Person.where(hbx_id: dep_id).first.full_name
        notice.enrollment = PdfTemplates::Enrollment.new({
          :dependents => names,
          :plan_year => bc_period.start_on.year,
          :effective_on => bc_period.start_on,
          :ivl_open_enrollment_start_on => bc_period.open_enrollment_start_on,
          :ivl_open_enrollment_end_on => bc_period.open_enrollment_end_on
          })
      end
    end
  end
end
