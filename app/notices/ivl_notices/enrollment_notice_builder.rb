class IvlNotices::EnrollmentNoticeBuilder < IvlNotice

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
    notice.mpi_indicator = self.mpi_indicator
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
    family = recipient.primary_family
    #temporary fix - in case of mutliple applications
    latest_application = family.applications.where(:assm_state.nin => ["draft"]).sort_by(&:submitted_at).last
    notice.assistance_year = latest_application.assistance_year

    family.enrollments.enrolled_and_renewing.each do |enrollment|
      notice.enrollments << append_enrollment_information(enrollment)
    end
    hbx = HbxProfile.current_hbx
    bc_period = hbx.benefit_sponsorship.benefit_coverage_periods.detect { |bcp| bcp if (bcp.start_on..bcp.end_on).cover?(TimeKeeper.date_of_record.next_year) }
    notice.ivl_open_enrollment_start_on = bc_period.open_enrollment_start_on
    notice.ivl_open_enrollment_end_on = bc_period.open_enrollment_end_on
  end

  def append_enrollment_information(enrollment)
    plan = PdfTemplates::Plan.new({
      plan_name: enrollment.plan.name,
      is_csr: enrollment.plan.is_csr?,
      plan_carrier: enrollment.plan.carrier_profile.organization.legal_name
      })
    PdfTemplates::Enrollment.new({
      premium: enrollment.total_premium.round(2),
      aptc_amount: enrollment.applied_aptc_amount.round(2),
      responsible_amount: (enrollment.total_premium - enrollment.applied_aptc_amount.to_f).round(2),
      phone: enrollment.phone_number,
      is_receiving_assistance: (enrollment.applied_aptc_amount > 0 || enrollment.plan.is_csr?) ? true : false,
      coverage_kind: enrollment.coverage_kind,
      effective_on: enrollment.effective_on,
      plan: plan,
      enrollees: enrollment.hbx_enrollment_members.inject([]) do |names, member|
        names << member.person.full_name.titleize
      end
    })
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