class ShopBrokerNotices::BrokerHiredNotice < ShopBrokerNotice
  Required= Notice::Required + []

  attr_accessor :broker
  attr_accessor :employer_profile

  def deliver
    build
    generate_pdf_notice
    non_discrimination_attachment
    attach_envelope
    upload_and_send_secure_message
    send_generic_notice_alert
  end

  def build
    notice.mpi_indicator = self.mpi_indicator
    notice.broker = PdfTemplates::Broker.new({
      full_name: broker.full_name.titleize,
      hbx_id: broker.hbx_id,
      assignment_date: employer_profile.broker_agency_accounts.detect{|br| br.is_active == true}.start_on
    })
    notice.primary_fullname = broker.full_name
    notice.er_legal_name = employer_profile.legal_name.titleize
    notice.er_first_name = employer_profile.staff_roles.first.first_name
    notice.er_last_name = employer_profile.staff_roles.first.last_name
    notice.broker_agency = employer_profile.broker_agency_profile.legal_name.titleize
    append_address(employer_profile.broker_agency_profile.organization.primary_office_location.address)
    append_hbe
  end

end

