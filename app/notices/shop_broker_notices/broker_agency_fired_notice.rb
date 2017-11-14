class ShopBrokerNotices::BrokerAgencyFiredNotice < ShopBrokerNotice
  Required= Notice::Required
  attr_accessor :employer_profile, :broker_agency_profile, :terminated_broker_account

  def initialize(employer_profile, args = {})
    self.employer_profile = employer_profile
    self.broker_agency_profile = employer_profile.broker_agency_accounts.unscoped.select{ |b| b.is_active == false}.sort_by(&:created_at).last.broker_agency_profile
    self.terminated_broker_account = employer_profile.broker_agency_accounts.unscoped.select{ |b| b.is_active == false}.sort_by(&:created_at).last
    broker_person = broker_agency_profile.primary_broker_role.person
    args[:recipient] = broker_person
    args[:to] = broker_agency_profile.legal_name
    args[:name] = broker_agency_profile.legal_name
    args[:recipient_document_store]= broker_person
    super(args)
  end

  def deliver
    build
    generate_pdf_notice
    non_discrimination_attachment
    attach_envelope
    upload_and_send_secure_message
  end

  def create_secure_inbox_message(notice)
    body = "<br>You can download the notice by clicking this link " +
        "<a href=" + "#{Rails.application.routes.url_helpers.authorized_document_download_path(recipient.class.to_s,
                                                                                               recipient.id, 'documents', notice.id )}?content_type=#{notice.format}&filename=#{notice.title.gsub(/[^0-9a-z]/i,'')}.pdf&disposition=inline" + " target='_blank'>" + notice.title + "</a>"
    message = broker_agency_profile.inbox.messages.build({ subject: subject, body: body, from: 'DC Health Link' })
    message.save!
  end

  def build
    append_address(broker_agency_profile.organization.primary_office_location.address)
    append_broker(broker_agency_profile)
    append_hbe
  end

  def append_broker(broker)
    return if broker.blank?
    location = broker.organization.primary_office_location
    broker_role = broker.primary_broker_role
    person = broker_role.person if broker_role
    return if person.blank? || location.blank?
    notice.first_name = person.first_name
    notice.last_name = person.last_name
    notice.primary_fullname = self.broker_agency_profile.legal_name
    notice.broker = PdfTemplates::Broker.new({
      organization: broker.legal_name,
      phone: location.phone,
      email: (person.home_email || person.work_email).address,
      web_address: broker.home_page
    })
    notice.mpi_indicator = self.mpi_indicator
    notice.employer_profile = self.employer_profile
    notice.broker_agency_profile = self.broker_agency_profile
    notice.terminated_broker_account = self.terminated_broker_account
    notice.employer_name = self.employer_profile.legal_name
  end

end
