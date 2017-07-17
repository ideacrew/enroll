class IvlNotices::EligibilityNoticeBuilder < IvlNotice

  def initialize(consumer_role, args = {})
    args[:recipient] = consumer_role.person.families.first.primary_applicant.person
    args[:notice] = PdfTemplates::ConditionalEligibilityNotice.new
    args[:market_kind] = 'individual'
    args[:recipient_document_store]= consumer_role.person.families.first.primary_applicant.person
    args[:to] = consumer_role.person.families.first.primary_applicant.person.work_email_or_best
    self.header = "notices/shared/header_ivl.html.erb"
    super(args)
  end

  def deliver
    build
    generate_pdf_notice
    attach_blank_page
    # attach_voter_application
    # prepend_envelope
    upload_and_send_secure_message

    if recipient.consumer_role.can_receive_electronic_communication?
      send_generic_notice_alert
    end

    if recipient.consumer_role.can_receive_paper_communication?
      store_paper_notice
    end
  end

  def attach_voter_application
    join_pdfs [notice_path, Rails.root.join('lib/pdf_templates', 'voter_application.pdf')]
  end

  def build
    append_data
    notice.primary_fullname = recipient.full_name.titleize || ""
    if recipient.mailing_address
      append_address(recipient.mailing_address)
    else
      # @notice.primary_address = nil
      raise 'mailing address not present'
    end
  end

  def append_data
    #Family has many applications - Pull the right application.
    family = recipient.primary_family
    application = recipient.primary_family.applications.first
    latest_application = family.applications.sort_by(&:submitted_at).last
    latest_application.applicants.each do |applicant|
      notice.individuals << append_applicant_information(applicant)
    end
    latest_application.tax_households.each do |th|
      notice.tax_households << append_tax_households(th)
    end
  end

  def append_tax_households(th)
    params = {
              csr_percent_as_integer: th.preferred_eligibility_determination.csr_percent_as_integer,
              max_aptc: th.preferred_eligibility_determination.max_aptc,
              aptc_csr_annual_household_income: th.preferred_eligibility_determination.aptc_csr_annual_household_income,
              aptc_annual_income_limit: th.preferred_eligibility_determination.aptc_annual_income_limit,
              csr_annual_income_limit: th.preferred_eligibility_determination.csr_annual_income_limit
              }
  end

  def append_applicant_information(applicant)
    params = {
              full_name: applicant.person.full_name,
              age: applicant.person.age_on(TimeKeeper.date_of_record),
              is_medicaid_chip_eligible: applicant.is_medicaid_chip_eligible,
              is_ia_eligible: applicant.is_ia_eligible,
              is_non_magi_medicaid_eligible: applicant.is_non_magi_medicaid_eligible,
              is_without_assistance: applicant.is_without_assistance,
              is_totally_ineligible: applicant.is_totally_ineligible
              }
  end

  def append_address(primary_address)
    notice.primary_address = PdfTemplates::NoticeAddress.new({
      street_1: capitalize_quadrant(primary_address.address_1.to_s.titleize),
      street_2: capitalize_quadrant(primary_address.address_2.to_s.titleize),
      city: primary_address.city.titleize,
      state: primary_address.state,
      zip: primary_address.zip
      })
  end

  def capitalize_quadrant(address_line)
    address_line.split(/\s/).map do |x|
      x.strip.match(/^NW$|^NE$|^SE$|^SW$/i).present? ? x.strip.upcase : x.strip
    end.join(' ')
  end

end