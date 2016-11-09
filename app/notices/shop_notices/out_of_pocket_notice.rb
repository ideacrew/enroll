class ShopNotices::OutOfPocketNotice < ShopNotice

  def initialize(employer_profile, args = {})
    args[:template] =  "notices/shop_notices/out_of_pocket_notice.html.erb"
    args[:market_kind] = 'shop'
    args[:notice] = PdfTemplates::EmployerNotice.new
    args[:recipient] = employer_profile
    args[:recipient_document_store] = employer_profile
    args[:name] = employer_profile.organization.legal_name
    self.header = "notices/shared/header_with_page_numbers.html.erb"
    super(args)
    self.subject=  "#{args[:subject]}"
  end

  def deliver
    build
    generate_pdf_notice
    upload_and_send_secure_message
  end

  # def build_and_save
  #   build
  #   generate_pdf_notice
  #   upload_to_amazonS3
  # end

  def move_to_employer_folder
    temp_employer_folder = FileUtils.mkdir_p(Rails.root.join("tmp", "#{@recipient.employer_profile.id}"))
    FileUtils.mv(notice_path, temp_employer_folder.join)
  end

  # def upload_to_amazonS3
  #   Aws::S3Storage.save(notice_path, 'notices')
  # rescue => e
  #   raise "unable to upload to amazon #{e}"
  # end


  def build
      @notice.start_on= @recipient.try(:plan_years).first.start_on
      @notice.census_employees = @recipient.census_employees.to_a
      @notice.legal_name= @recipient.organization.legal_name
      @notice.metal_leval= @recipient.plan_years.first.try(:benefit_groups).try(:first).try(:reference_plan).try(:metal_level)
      @notice.benefit_group_package_name= @recipient.plan_years.first.benefit_groups.first.title
      @notice.plan_year = @recipient.try(:plan_years).first.try(:benefit_groups).first.try(:reference_plan).name
      @notice.family_contribution= @recipient.plan_years.first.benefit_groups.first.relationship_benefits
      @notice.carrier =@recipient.plan_years.first.benefit_groups.first.reference_plan.carrier_profile.legal_name
      @notice.data = {:url => url} 
  end

  def url
    "https://staging.checkbookhealth.org/shop/dc/"
  end

  # @param recipient is a Person object
  def send_email_notice
    attachments={"#{subject}": notice_path}
    UserMailer.generic_notice_alert(@notice.primary_fullname,subject,to,attachments).deliver_now
  end
end 
