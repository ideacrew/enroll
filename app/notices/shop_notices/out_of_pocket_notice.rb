class ShopNotices::OutOfPocketNotice < ShopNotice

  def initialize(employer_profile, args = {})
    super(args)
    @employer_profile = employer_profile
    @template = args[:template] || "notices/shop_notices/out_of_pocket_notice.html.erb"
    @delivery_method = args[:delivery_method].split(',')
    @recipient = @employer_profile.employee_roles.first.person
    @secure_message_recipient = @recipient.primary_family
    @family = @recipient.primary_family
    @market_kind = 'shop'

    @notice = PdfTemplates::EmployerNotice.new
  end



  def build
    # @notice.primary_fullname = @recipient.full_name.titleize
    # @notice.primary_identifier = @employer_profile.hbx_id
    # append_primary_address(@recipient.mailing_address || @employer_profile.organization.office_locations.first.address)
    # append_hbe
    # append_broker(@employer_profile.broker_agency_profile)
  end
end 
