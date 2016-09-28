class ShopNotices::OutOfPocketNotice < ShopNotice

  def initialize(census_employee, args = {})
    args[:template] =  "notices/shop_notices/out_of_pocket_notice.html.erb"
    args[:market_kind] = 'shop'
    args[:notice] = PdfTemplates::EmployerNotice.new
    args[:recipient] = census_employee
    args[:recipient_document_store] = "Not needed"
    self.header = "notices/shared/header_with_page_numbers.html.erb"
    super(args)
    # self.data = args[:data]
    # @to= @recipient.email.address
  end

  def deliver
    build
    generate_pdf_notice
    send_email_notice
  end

  def build
    @notice.primary_fullname = @recipient.full_name.titleize
    ## Build all the data needed here 

  end

  # @param recipient is a Person object
  def send_email_notice
    attachments={"#{subject}": notice_path}
    UserMailer.generic_notice_alert(@notice.primary_fullname,subject,to,attachments).deliver_now
  end
end 
