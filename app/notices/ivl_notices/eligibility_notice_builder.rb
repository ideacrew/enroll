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
    append_hbe
    build
    generate_pdf_notice
    attach_blank_page
    attach_appeals
    attach_non_discrimination
    attach_taglines
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
    notice.mpi_indicator = self.mpi_indicator
    notice.notification_type = self.event_name
    notice.primary_fullname = recipient.full_name.titleize || ""
    notice.primary_firstname = recipient.first_name.titleize || ""
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
    #temporary fix - in case of mutliple applications
    latest_application = family.applications.where(:aasm_state.nin => ["draft"]).sort_by(&:submitted_at).last
    notice.coverage_year = latest_application.assistance_year
    latest_application.applicants.each do |applicant|
      notice.individuals << append_applicant_information(applicant)
    end
    latest_application.tax_households.each do |th|
      notice.tax_households << append_tax_households(th)
    end
    hbx = HbxProfile.current_hbx
    bc_period = hbx.benefit_sponsorship.benefit_coverage_periods.detect { |bcp| bcp if (bcp.start_on..bcp.end_on).cover?(TimeKeeper.date_of_record.next_year) }
    notice.ivl_open_enrollment_start_on = bc_period.open_enrollment_start_on
    notice.ivl_open_enrollment_end_on = bc_period.open_enrollment_end_on
  end

  def append_tax_households(th)
    PdfTemplates::TaxHousehold.new({
      csr_percent_as_integer: th.preferred_eligibility_determination.csr_percent_as_integer.to_i,
      max_aptc: th.preferred_eligibility_determination.max_aptc.to_i,
      aptc_csr_annual_household_income: th.preferred_eligibility_determination.aptc_csr_annual_household_income.to_i,
      aptc_annual_income_limit: th.preferred_eligibility_determination.aptc_annual_income_limit.to_i,
      csr_annual_income_limit: th.preferred_eligibility_determination.csr_annual_income_limit.to_i,
    })
  end

  def append_applicant_information(applicant)
    reason_for_ineligibility = []
    reason_for_ineligibility << "this person isn’t a resident of the District of Columbia. Go to healthcare.gov to learn how to apply for coverage in the right state." if !applicant.person.is_dc_resident?
    reason_for_ineligibility << "this person is currently serving time in jail or prison for a criminal conviction." if applicant.person.is_incarcerated
    reason_for_ineligibility << "this person doesn’t have an eligible immigration status, but may be eligible for a local medical assistance program called the DC Health Care Alliance. For more information, please contact #{Settings.site.short_name} at #{notice.hbe.phone}." if lawful_presence_outstanding?(applicant.person)

    PdfTemplates::Individual.new({
      tax_household: append_tax_households(applicant.tax_household),
      first_name: applicant.person.first_name.titleize,
      full_name: applicant.person.full_name.titleize,
      age: applicant.person.age_on(TimeKeeper.date_of_record),
      is_medicaid_chip_eligible: applicant.is_medicaid_chip_eligible,
      is_ia_eligible: applicant.is_ia_eligible,
      indian_conflict: applicant.person.consumer_role.indian_conflict?,
      is_non_magi_medicaid_eligible: applicant.is_non_magi_medicaid_eligible,
      is_without_assistance: applicant.is_without_assistance,
      magi_medicaid_monthly_income_limit: applicant.magi_medicaid_monthly_income_limit,
      has_access_to_affordable_coverage: applicant.benefits.where(:kind => "is_eligible").present?,
      immigration_unverified: applicant.person.consumer_role.outstanding_verification_types.include?("Immigration status"),
      no_aptc_because_of_income: (applicant.preferred_eligibility_determination.aptc_csr_annual_household_income > applicant.preferred_eligibility_determination.aptc_annual_income_limit) ? true : false,
      no_csr_because_of_income: (applicant.preferred_eligibility_determination.aptc_csr_annual_household_income > applicant.preferred_eligibility_determination.csr_annual_income_limit) ? true : false,
      is_totally_ineligible: applicant.is_totally_ineligible,
      reason_for_ineligibility: reason_for_ineligibility
    })
  end

  def lawful_presence_outstanding?(person)
    person.consumer_role.outstanding_verification_types.include?('Citizenship') || person.consumer_role.outstanding_verification_types.include?('Immigration status')
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