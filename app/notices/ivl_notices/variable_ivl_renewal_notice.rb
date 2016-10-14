class IvlNotices::VariableIvlRenewalNotice < IvlNotice
  attr_accessor :family, :data,:identifier, :person,:address

  def initialize(consumer_role, args = {})
    args[:recipient] = consumer_role.person
    args[:notice] = PdfTemplates::ConditionalEligibilityNotice.new
    args[:market_kind] = 'individual'
    args[:recipient_document_store]= consumer_role.person
    args[:to] = consumer_role.person.work_email_or_best
    self.data = args[:data]
    self.header = "notices/shared/header_with_page_numbers.html.erb"
    super(args)
  end

  def build
    family = recipient.primary_family
    append_enrollments(family.all_enrollments)
    notice.primary_identifier = "Account ID: #{identifier}"
    notice.primary_fullname = recipient.full_name.titleize || ""
    if recipient.mailing_address
      append_address(recipient.mailing_address)
    else  
      # @notice.primary_address = nil
      raise 'mailing address not present' 
    end
  end

  def append_enrollments(hbx_enrollments)
    enrollments_for_notice = []
    enrollments_for_notice << health_enrollment(hbx_enrollments)
    enrollments_for_notice << dental_enrollment(hbx_enrollments)
    enrollments_for_notice.compact!
    enrollments_for_notice.each do |hbx_enrollment|
      @notice.enrollments << build_enrollment(hbx_enrollment)
    end
  end

  def build_enrollment(hbx_enrollment)
    PdfTemplates::EnrollmentWithPlanData.new({
      plan_name: hbx_enrollment.plan.name,
      premium: hbx_enrollment.total_premium,
      phone: hbx_enrollment.phone_number,
      effective_on: hbx_enrollment.effective_on,
      selected_on: hbx_enrollment.created_at,
      metal_level: hbx_enrollment.plan.metal_level,
      coverage_kind: hbx_enrollment.plan.coverage_kind,
      plan_carrier: hbx_enrollment.plan.carrier_profile.organization.legal_name,
      hsa_plan: hbx_enrollment.plan.hsa_plan?,
      enrollees: hbx_enrollment.hbx_enrollment_members.inject([]) do |names, member|
        names << member.person.full_name.titleize
        end
    })
  end

  def health_enrollment(hbx_enrollments)
    return hbx_enrollments.where(coverage_kind: "health").sort_by{|hbx_enrollment| hbx_enrollment.effective_on}.last
  end

  def dental_enrollment(hbx_enrollments)
    return hbx_enrollments.where(coverage_kind: "dental").sort_by{|hbx_enrollment| hbx_enrollment.effective_on}.last
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