class ShopEmployerNotices::EmployerBrokerFiredNotice < ShopEmployerNotice

  attr_accessor :employer_profile

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
    broker = employer_profile.broker_agency_accounts.unscoped.last.broker_agency_profile
    broker_role = broker.primary_broker_role
    person = broker_role.person if broker_role.present?
    notice.broker = PdfTemplates::Broker.new({
                                                 first_name: person.first_name,
                                                 last_name: person.last_name,
                                                 terminated_on: employer_profile.broker_agency_accounts.unscoped.last.end_on,
                                                 organization: broker.legal_name })
  end

end
