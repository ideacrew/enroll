# class ShopBrokerNotices::BrokerFiredNotice < ShopBrokerNotice
#   Required= Notice::Required
#   attr_accessor :employer_profile, :broker_agency_profile, :terminated_broker_account

#   def initialize(employer_profile, args = {})
#     self.employer_profile = employer_profile
#     self.broker_agency_profile = employer_profile.broker_agency_accounts.unscoped.last.broker_agency_profile
#     self.terminated_broker_account = employer_profile.broker_agency_accounts.unscoped.last
#     broker_person = broker_agency_profile.try(:primary_broker_role).try(:person)
#     args[:recipient] = broker_person
#     args[:market_kind]= 'shop'
#     args[:notice] = PdfTemplates::Broker.new
#     args[:to] = broker_agency_profile.try(:legal_name)
#     args[:name] = broker_agency_profile.try(:legal_name)
#     args[:recipient_document_store]= broker_person
#     self.header = "notices/shared/shop_header.html.erb"
#     super(args)
#   end

#   def deliver
#     build
#     generate_pdf_notice
#     non_discrimination_attachment
#     attach_envelope
#     upload_and_send_secure_message
#   end

#   # def create_secure_inbox_message(notice)
#   #   body = "<br>You can download the notice by clicking this link " +
#   #       "<a href=" + "#{Rails.application.routes.url_helpers.authorized_document_download_path(recipient.class.to_s,
#   #                                                                                              recipient.id, 'documents', notice.id )}?content_type=#{notice.format}&filename=#{notice.title.gsub(/[^0-9a-z]/i,'')}.pdf&disposition=inline" + " target='_blank'>" + notice.title + "</a>"
#   #   message = recipient.inbox.messages.build({ subject: subject, body: body, from: 'DC Health Link' })
#   #   message.save!
#   # end

#   def build
#     append_address(broker_agency_profile.organization.primary_office_location.address)
#     append_broker(broker_agency_profile)
#     append_hbe
#   end

#   def append_broker(broker)
#     return if broker.blank?
#     location = broker.organization.primary_office_location
#     broker_role = broker.primary_broker_role
#     person = broker_role.person if broker_role
#     return if person.blank? || location.blank?
#     notice.first_name = person.first_name
#     notice.last_name = person.last_name
#     notice.primary_fullname = self.broker_agency_profile.try(:legal_name)
#     notice.organization = broker.legal_name
#     notice.phone = location.phone.try(:to_s)
#     notice.email = (person.home_email || person.work_email).try(:address)
#     notice.web_address = broker.home_page
#     notice.mpi_indicator = self.mpi_indicator
#     notice.employer_profile = self.employer_profile
#     notice.broker_agency_profile = self.broker_agency_profile
#     notice.terminated_broker_account = self.terminated_broker_account
#     notice.employer_name = self.employer_profile.try(:legal_name)
#   end

# end


class ShopBrokerNotices::BrokerFiredNotice < ShopBrokerNotice
  Required= Notice::Required + []

  attr_accessor :broker
  attr_accessor :employer_profile

  def initialize(employer_profile, args = {})
    self.employer_profile = employer_profile
    broker_role = employer_profile.broker_agency_accounts.unscoped.last.broker_agency_profile.primary_broker_role.person
    self.broker = broker_role
    args[:recipient] = broker
    args[:market_kind]= 'shop'
    args[:notice] = PdfTemplates::BrokerNotice.new
    args[:to] = broker.work_email_or_best
    args[:name] = broker.full_name
    args[:recipient_document_store] = broker
    self.header = "notices/shared/header_with_page_numbers.html.erb"
    super(args)
  end


  def deliver
    build
    generate_pdf_notice
    attach_envelope
    non_discrimination_attachment
    upload_and_send_secure_message
    send_generic_notice_alert
  end

   def build
    notice.first_name = broker.first_name.titleize
    notice.last_name = broker.last_name.titleize
    notice.hbx_id = broker.hbx_id
    notice.mpi_indicator = self.mpi_indicator
    notice.employer_name = employer_profile.legal_name.titleize
    notice.employer_first_name = employer_profile.staff_roles.first.first_name.titleize
    notice.employer_last_name = employer_profile.staff_roles.first.last_name.titleize
    notice.termination_date = employer_profile.broker_agency_accounts.unscoped.last.end_on
    notice.broker_agency = employer_profile.broker_agency_accounts.unscoped.last.broker_agency_profile.legal_name.titleize
    append_hbe
    append_address(employer_profile.broker_agency_accounts.unscoped.last.broker_agency_profile.organization.primary_office_location.address)
  end

 def attach_envelope
    join_pdfs [notice_path, Rails.root.join('lib/pdf_templates', 'envelope_without_address.pdf')]
  end

  def non_discrimination_attachment
    join_pdfs [notice_path, Rails.root.join('lib/pdf_templates', 'shop_non_discrimination_attachment.pdf')]
  end

  def append_address(primary_address)
    notice.primary_address = PdfTemplates::NoticeAddress.new({
                                 street_1: primary_address.address_1.titleize,
                                 street_2: primary_address.address_2.titleize,
                                 city: primary_address.city.titleize,
                                 state: primary_address.state,
                                 zip: primary_address.zip
                             })
  end

end