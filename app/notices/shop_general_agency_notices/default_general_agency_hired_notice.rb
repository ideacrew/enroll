class ShopGeneralAgencyNotices::DefaultGeneralAgencyHiredNotice < ShopGeneralAgencyNotice

  attr_accessor :general_agency_profile, :broker_agency_profile_id

  def initialize(general_agency_profile, args = {})
    @broker_agency_profile = BrokerAgencyProfile.find(args[:options][:broker_agency_profile_id])
    super(general_agency_profile, args)
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
    broker = @broker_agency_profile.primary_broker_role.person
    notice.general_agency = PdfTemplates::GeneralAgencyNotice.new({
          :broker_fullname => broker.full_name
        })
  end
end
