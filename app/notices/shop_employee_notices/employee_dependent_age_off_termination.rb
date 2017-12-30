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
    current_date = TimeKeeper.date_of_record
    ben_sponsorship = HbxProfile.current_hbx.benefit_sponsorship
    current_open_enrollment_coverage = ben_sponsorship.benefit_coverage_periods.where(open_enrollment_end_on: Settings.aca.individual_market.open_enrollment.end_on ).first
    bc_period = current_open_enrollment_coverage.open_enrollment_end_on >= current_date ? current_open_enrollment_coverage : ben_sponsorship.renewal_benefit_coverage_period
    is_congress = census_employee.employee_role.benefit_group.is_congress
    names = []
    if bc_period.present?
      self.dep_hbx_ids.each do |dep_id|
        names << Person.where(hbx_id: dep_id).first.full_name
        notice.enrollment = PdfTemplates::Enrollment.new({
          :dependents => names,
          :terminated_on => current_date.end_of_month,
          :is_congress => is_congress,
          :plan_year => bc_period.start_on.year,
          :effective_on => bc_period.start_on,
          :ivl_open_enrollment_start_on => bc_period.open_enrollment_start_on,
          :ivl_open_enrollment_end_on => bc_period.open_enrollment_end_on
          })
      end
    end
  end
end
