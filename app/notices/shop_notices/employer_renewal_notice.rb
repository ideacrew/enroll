class ShopNotices::EmployerRenewalNotice < ShopNotice

  attr_accessor :employer_profile

  def initialize(employer_profile,  args = {})
    self.employer_profile = employer_profile
    args[:recipient] = employer_profile
    args[:market_kind]= 'shop'
    args[:notice] = PdfTemplates::EmployerNotice.new
    args[:to] = employer_profile.staff_roles.first.work_email_or_best
    args[:name] = "testing"
    args[:recipient_document_store]= employer_profile
    self.header = "notices/shared/header_with_page_numbers.html.erb"
    super(args)
  end

  def deliver
    build
    super
  end

  def create_secure_inbox_message(notice)
    if notice.description == "MPI_SHOPRA"
      body = "<br>Thank you for finalizing your plan offerings to your employees through #{Settings.site.short_name}. <br> Based upon the information you have provided, you are eligible to offer group health coverage to your employees through #{Settings.site.short_name}. Click" +
            "<a href=" + "#{Rails.application.routes.url_helpers.authorized_document_download_path(recipient.class.to_s,
              recipient.id, 'documents', notice.id )}?content_type=#{notice.format}&filename=#{notice.title.gsub(/[^0-9a-z]/i,'')}.pdf&disposition=inline" + " target='_blank'>" + " here " + "</a>"+"for more details"
    elsif notice.description == "MPI_SHOPRB"
      body = "<br>DC Health Link finalized your plan offerings based on your prior year plan offerings due to the passing of the deadlines to do so, found <a href='https://dchealthlink.com/smallbusiness/employer-coverage-deadlines'>here</a>. <br> Based upon the information you have provided, you are eligible to offer group health coverage to your employees through #{Settings.site.short_name}. Click" +
        "<a href=" + "#{Rails.application.routes.url_helpers.authorized_document_download_path(recipient.class.to_s,
          recipient.id, 'documents', notice.id )}?content_type=#{notice.format}&filename=#{notice.title.gsub(/[^0-9a-z]/i,'')}.pdf&disposition=inline" + " target='_blank'>" +" here "+ "</a>"+"for more details"
    end

    message = recipient.inbox.messages.build({ subject: subject, body: body, from: 'DC Health Link' })
    message.save!
  end

  def build
    notice.primary_fullname = employer_profile.staff_roles.first.full_name.titleize
    notice.employer_name = recipient.organization.legal_name.titleize
    notice.primary_identifier = employer_profile.hbx_id
    append_address(employer_profile.organization.primary_office_location.address)
    append_hbe
    append_broker(employer_profile.broker_agency_profile)
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
