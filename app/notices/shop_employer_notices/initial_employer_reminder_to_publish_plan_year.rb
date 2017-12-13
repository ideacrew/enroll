class ShopEmployerNotices::InitialEmployerReminderToPublishPlanYear < ShopEmployerNotice

   def build
    notice.notification_type = self.event_name
    notice.mpi_indicator = self.mpi_indicator
    notice.primary_fullname = employer_profile.staff_roles.first.full_name.titleize
    notice.employer_name = recipient.organization.legal_name.titleize
    notice.primary_identifier = employer_profile.hbx_id
    notice.aasm_state = self.aasm_state
    append_address(employer_profile.organization.primary_office_location.address)
    append_hbe
    append_broker(employer_profile.broker_agency_profile)
  end

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
    plan_year = employer_profile.plan_years.where(:aasm_state.in => [notice.aasm_state, "draft"]).first
    notice.plan_year = PdfTemplates::PlanYear.new({
          :start_on => plan_year.start_on,
        })
    notice.plan_year.binder_payment_due_date = PlanYear.calculate_open_enrollment_date(plan_year.start_on)[:binder_payment_due_date]
  end
end