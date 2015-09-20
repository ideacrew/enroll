class ShopNotices::EmployerNotice < Notice

  attr_accessor :from, :to, :subject, :template, :notice_data

  def initialize(employer, args = {})
    super
    @employer = employer
    @to = 'raghuramg83@gmail.com'
    @template = args[:template] || "notices/shop_notices/employer_renewal"
    @email_notice = args[:email_notice] || true
    @paper_notice = args[:paper_notice] || true
  end

  def deliver
    # send_email_notice if @email_notice
    # send_pdf_notice if @paper_notice
    # send_email_notice
    mock_notice_object
    generate_pdf_notice
  end

  def mock_notice_object
    @notice = PdfTemplates::EmployerNotice.new({ 
      primary_fullname: 'Shane Levy', 
      primary_identifier: '642323233', 
      employer_name: 'Legal Inc',
      primary_address: PdfTemplates::NoticeAddress.new({
        street_1: "100 K ST NE",
        street_2: "Suite 100",
        city: "Washington DC",
        state: "DC",
        zip: "20005"
      })
    })
  end

  def build
    @notice = PdfTemplates::EmployerNotice.new
    @notice.primary_fullname = @employer.full_name.titleize
    @notice.primary_identifier = @consumer.hbx_id
    append_address(@consumer.addresses[0])
  end

  def append_address(primary_address)
    @notice.primary_address = PdfTemplates::NoticeAddress.new({
      street_1: primary_address.address_1.titleize,
      street_2: primary_address.address_2.titleize,
      city: primary_address.city.titleize,
      state: primary_address.state,
      zip: primary_address.zip
      })
  end
end



