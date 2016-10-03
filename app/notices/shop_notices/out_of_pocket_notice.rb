class ShopNotices::OutOfPocketNotice < ShopNotice
  attr_accessor :url

  def initialize(census_employee, args = {})
    args[:template] =  "notices/shop_notices/out_of_pocket_notice.html.erb"
    args[:market_kind] = 'shop'
    args[:notice] = PdfTemplates::EmployerNotice.new
    args[:recipient] = census_employee
    args[:recipient_document_store] = "Not needed"
    self.header = "notices/shared/header_with_page_numbers.html.erb"
    self.url = args[:data]
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
    @notice.start_on= @recipient.employer_profile.plan_years.first.start_on
    @notice.legal_name= @recipient.employer_profile.organization.legal_name
    @notice.benefit_group_package_name= @recipient.employer_profile.plan_years.first.benefit_groups.first.title
    @notice.family_contribution= @recipient.employer_profile.plan_years.first.benefit_groups.first.relationship_benefits
    @notice.reference_plan =@recipient.active_benefit_group.reference_plan
    @notice.data = {:url => url}
    
    ## Build all the data needed here 

  end

  # @param recipient is a Person object
  def send_email_notice
    attachments={"#{subject}": notice_path}
    UserMailer.generic_notice_alert(@notice.primary_fullname,subject,to,attachments).deliver_now
  end
end 
