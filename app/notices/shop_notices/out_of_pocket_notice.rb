class ShopNotices::OutOfPocketNotice < ShopNotice

  def initialize(employer_profile, args = {})
    args[:template] =  "notices/shop_notices/out_of_pocket_notice.html.erb"
    args[:market_kind] = 'shop'
    args[:notice] = PdfTemplates::EmployerNotice.new
    args[:recipient] = employer_profile
    args[:recipient_document_store] = employer_profile
    args[:name] = employer_profile.organization.legal_name
    self.header = "notices/shared/header.html.erb"
    super(args)
    self.subject=  "#{args[:subject]}"
  end

  def deliver
    build
    generate_pdf_notice
    upload_and_send_secure_message
  end

  def move_to_employer_folder
    temp_employer_folder = FileUtils.mkdir_p(Rails.root.join("tmp", "#{@recipient.employer_profile.id}"))
    FileUtils.mv(notice_path, temp_employer_folder.join)
  end

  def build
      @notice.start_on= @recipient.try(:active_and_published_plan_year).start_on
      @notice.benefit_group_assignments =  @recipient.census_employees.map(&:active_benefit_group_assignment).compact.group_by(&:benefit_group_id)
      bg_ids = @recipient.active_and_published_plan_year.benefit_groups.map(&:id)
      @notice.benefit_group_assignments.delete_if{|bg_id, assignments| !bg_ids.include?(bg_id)}
      @notice.legal_name= @recipient.organization.legal_name
      @notice.data = {:url => url} 
  end

  def url
    "https://staging.checkbookhealth.org/shop/dc/"
  end

def create_secure_inbox_message(notice)
    body = "<p><br><strong>Plan Match:  Help your employees find the right health plan based on their needs and budget!</strong></p>" +
            "<p><br>To use Plan Match, your employees will need to provide some basic information about your plan offerings and contributions.  Click here to download a custom set of instructions that you can share with your eligible employees to enable them to use Plan Match to find the right health plan for them:</p>" +
            # "<br><p><u>Employee Plan Match – Instructions for Your Eligible Employees</u></p>" + 
            "<br><a href=" + "#{Rails.application.routes.url_helpers.authorized_document_download_path(recipient.class.to_s, 
              recipient.id, 'documents', notice.id )}?content_type=#{notice.format}&filename=#{notice.title.gsub(/[^0-9a-z]/i,'')}.pdf&disposition=inline" + " target='_blank'>" + "Employee Plan Match – Instructions for Your Eligible Employees"  + "</a>" +
            "<br></p><strong>What is Plan Match? </strong> " +
            "<br>Plan Match, DC Health Link's health plan comparison tool powered by Consumers' CHECKBOOK takes your employees through a few simple steps to find the best health plan for them.</p>" +
            "<br>With this anonymous tool, your employees can find every plan that you choose to make available to them through DC Health Link, and then compare plans based on total estimated cost (not just premiums or deductibles), plan features, doctor availability and more.  Consumers CHECKBOOK has over 35 years of experience helping consumers choose the best plans.</p>" +
            "<br><p><strong>Who can I share my custom Plan Match instructions with? </strong>" +
            "<br>Plan Match is a tool for your employees who are eligible for the health plan(s) you offer through DC Health Link.  Plan Match can be used anonymously by your eligible employees and their family members to compare health plan options and find the right health plan for their needs and budget.  Employees can also use Plan Match during the year when they experience a life event, such as marriage, birth, or loss of other coverage, to help determine the right health plan for them under their new circumstances.  Because Plan Match is truly anonymous, you could even share it with prospective employees who want to see what health plan options are available as part of your benefits offerings. </p>" +
            "<br><p><strong>Can employees enroll directly using Plan Match? </strong>" +
            "<br>Since Plan Match is an anonymous health plan comparison tool, eligible employees will still need to log into their DCHealthLink.com employee account to quickly complete their plan selection.</p>"
    message = recipient.inbox.messages.build({ subject: subject, body: body, from: 'DC Health Link' })
    message.save!
  end




  #TODO remove of not used
  def send_email_notice
    attachments={"#{subject}": notice_path}
    UserMailer.generic_notice_alert(@notice.primary_fullname,subject,to,attachments).deliver_now
  end
end 
