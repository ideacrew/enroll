class IvlNotices::IneligibilityNoticeBuilder < IvlNotice

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
    family = recipient.primary_family
    notice.has_applied_for_assistance = family.applications.where(:assistance_year => TimeKeeper.date_of_record.year).present?
    latest_application = family.applications.sort_by(&:submitted_at).last
    if (notice.has_applied_for_assistance && latest_application.present? && latest_application.is_family_totally_ineligibile)
      notice.request_full_determination = latest_application.request_full_determination
      notice.is_family_totally_ineligibile = latest_application.is_family_totally_ineligibile
      latest_application.applicants.map(&:person).uniq.each do |person|
        notice.individuals << append_family_members(person)
      end
    else
      family.family_members.map(&:person).uniq.each do |person|
        notice.individuals << append_family_members(person)
      end
    end
  end

  def append_family_members(person)
    reason_for_ineligibility = []
    reason_for_ineligibility << "this person isn’t a resident of the District of Columbia. Go to healthcare.gov to learn how to apply for coverage in the right state." if !person.is_dc_resident?
    reason_for_ineligibility << "this person is currently serving time in jail or prison for a criminal conviction." if person.is_incarcerated
    reason_for_ineligibility << "this person doesn’t have an eligible immigration status, but may be eligible for a local medical assistance program called the DC Health Care Alliance. For more information, please contact #{Settings.site.short_name} at #{notice.hbe.phone}." if lawful_presence_outstanding?(person)

    PdfTemplates::Individual.new({
      first_name: person.first_name.titleize,
      full_name: person.full_name.titleize,
      :age => person.age_on(TimeKeeper.date_of_record),
      :reason_for_ineligibility =>  reason_for_ineligibility
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