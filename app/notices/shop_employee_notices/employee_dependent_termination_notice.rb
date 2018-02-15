class ShopEmployeeNotices::EmployeeDependentTerminationNotice < ShopEmployeeNotice
  attr_accessor :census_employee

  def deliver
    build
    append_data
    generate_pdf_notice
    attach_envelope
    non_discrimination_attachment
    upload_and_send_secure_message
    send_generic_notice_alert
  end

  def append_data
    now = TimeKeeper.date_of_record
    names = []
    if census_employee.active_benefit_group_assignment.present? && census_employee.active_benefit_group_assignment.hbx_enrollment.present? && census_employee.active_benefit_group_assignment.hbx_enrollment.hbx_enrollment_members.size >= 1
      census_employee.active_benefit_group_assignment.hbx_enrollment.hbx_enrollment_members.reject(&:is_subscriber).each do |dependent|
        dep = dependent.person
        age = now.year - dep.dob.year - ((now.month > dep.dob.month || (now.month == dep.dob.month && now.day >= dep.dob.day)) ? 0 : 1)
        if (dep.age_on(now.end_of_month) >= 26 && age < 27) && (now.month == dep.dob.month)
          names << dep.full_name
          notice.enrollment = PdfTemplates::Enrollment.new({
                                                               :dependents => names,
                                                               :dependent_dob => now.end_of_month
                                                           })
        end
      end
    end
  end

end