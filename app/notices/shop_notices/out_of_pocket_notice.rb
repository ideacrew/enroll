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
    self.subject=  "#{args[:subject]}_#{census_employee.first_name}_#{census_employee.last_name}"
    self.to= @recipient.email.address
  end

  def deliver
    build
    generate_pdf_notice
    send_email_notice
  end

  def build_and_save
    build
    generate_pdf_notice
    move_to_employer_folder
  end

  def move_to_employer_folder
    temp_employer_folder = FileUtils.mkdir_p(Rails.root.join("tmp", "#{@recipient.employer_profile.id}"))
    FileUtils.mv(notice_path, temp_employer_folder.join)
  end

  def build
    raise "No Active plan year for employer" if @recipient.employer_profile.active_plan_year
    @notice.primary_fullname = @recipient.full_name.titleize
    @notice.start_on= @recipient.try(:employer_profile).try(:plan_years).first.start_on
    @notice.legal_name= @recipient.employer_profile.organization.legal_name
    @notice.metal_leval= @recipient.employer_profile.plan_years.first.try(:benefit_groups).try(:first).try(:reference_plan).try(:metal_level)
    @notice.benefit_group_package_name= @recipient.employer_profile.plan_years.first.benefit_groups.first.title
    @notice.family_contribution= @recipient.employer_profile.plan_years.first.benefit_groups.first.relationship_benefits
    @notice.reference_plan =@recipient.active_benefit_group.reference_plan
    @notice.carrier =@recipient.employer_profile.plan_years.first.benefit_groups.first.reference_plan.carrier_profile.legal_name
    @notice.data = {:url => url}  
  end

  # @param recipient is a Person object
  def send_email_notice
    attachments={"#{subject}": notice_path}
    UserMailer.generic_notice_alert(@notice.primary_fullname,subject,to,attachments).deliver_now
  end
end 
