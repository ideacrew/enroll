class ShopEmployerNotices::OutOfPocketNotice < ShopEmployerNotice

  def deliver
    build
    append_data
    generate_pdf_notice
    attach_envelope
    non_discrimination_attachment
    upload_and_send_secure_message
  end

  def move_to_employer_folder
    temp_employer_folder = FileUtils.mkdir_p(Rails.root.join("tmp", "#{@recipient.employer_profile.id}"))
    FileUtils.mv(notice_path, temp_employer_folder.join)
  end

  def append_data
    published_plan_years = @recipient.plan_years.published_or_renewing_published
    @notice.benefit_group_assignments = published_plan_years.collect{|py| py.benefit_groups}.flatten.group_by(&:id)
    @notice.data = {:url => url}
  end

  def url
    "https://dc.checkbookhealth.org/shop/dc/"
  end

  def create_secure_inbox_message(notice)
    body = "<p><br><strong>Plan Match:  Help your employees find the right health plan based on their needs and budget!</strong></p>" +
            "<p><br>To use Plan Match, your employees will need to provide some basic information about your plan offerings and contributions.  Click here to download a custom set of instructions that you can share with your eligible employees to enable them to use Plan Match to find the right health plan for them:</p>" +
            "<br><a href=" + "#{Rails.application.routes.url_helpers.authorized_document_download_path(recipient.class.to_s,
              recipient.id, 'documents', notice.id )}?content_type=#{notice.format}&filename=#{notice.title.gsub(/[^0-9a-z]/i,'')}.pdf&disposition=inline" + " target='_blank'>" + "Employee Plan Match – Instructions for Your Eligible Employees"  + "</a>" +
            "<br></p><strong>What is Plan Match? </strong> " +
            "<br>Plan Match, #{Settings.site.short_name}'s health plan comparison tool powered by Consumers' CHECKBOOK takes your employees through a few simple steps to find the best health plan for them.</p>" +
            "<br>With this anonymous tool, your employees can find every plan that you choose to make available to them through #{Settings.site.short_name}, and then compare plans based on total estimated cost (not just premiums or deductibles), plan features, doctor availability and more.  Consumers CHECKBOOK has over 35 years of experience helping consumers choose the best plans.</p>" +
            "<br><p><strong>Who can I share my custom Plan Match instructions with? </strong>" +
            "<br>Plan Match is a tool for your employees who are eligible for the health plan(s) you offer through #{Settings.site.short_name}.  Plan Match can be used anonymously by your eligible employees and their family members to compare health plan options and find the right health plan for their needs and budget.  Employees can also use Plan Match during the year when they experience a life event, such as marriage, birth, or loss of other coverage, to help determine the right health plan for them under their new circumstances.  Because Plan Match is truly anonymous, you could even share it with prospective employees who want to see what health plan options are available as part of your benefits offerings. </p>" +
            "<br><p><strong>Can employees enroll directly using Plan Match? </strong>" +
            "<br>Since Plan Match is an anonymous health plan comparison tool, eligible employees will need to log into their DCHealthLink.com account to complete their plan selection.</p>"
    message = recipient.inbox.messages.build({ subject: subject, body: body, from: "#{Settings.site.short_name}"})
    message.save!
  end

end
