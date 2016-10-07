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

  def deliver
    build
    generate_pdf_notice
    attach_blank_page
    attach_dchl_rights
    prepend_envelope
    upload_and_send_secure_message

    if recipient.consumer_role.can_receive_electronic_communication?
      send_generic_notice_alert
    end

    if recipient.consumer_role.can_receive_paper_communication?
      store_paper_notice
    end
  end

  def build
    family = recipient.primary_family
    append_data
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

  def append_data
    notice.individuals=data.collect do |datum|
        
        # person = Person.where(:hbx_id => datum["hbx_id"]).first
        PdfTemplates::Individual.new({
          :full_name => datum["full_name"],
          :incarcerated=>datum["incarcerated"].try(:upcase) == "N" ? "No" : "",
          :citizen_status=> citizen_status(datum["citizen_status"]),
          :residency_verified => datum["resident"].try(:upcase) == "Y"  ? "District of Columbia Resident" : "Not a District of Columbia Resident",
          :projected_amount => datum["actual_income"],
          :taxhh_count => datum["taxhhcount"],
          :uqhp_reason => datum["uqhp_reason"],
          :tax_status => filer_type(datum["filer_type"]),
          :mec => datum["mec"].upcase == "N" ? "None" : "Yes"

        })
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

  def filer_type(type)
    case type
    when "Filers"
      "Tax Filer"
    when "Dependents"
      "Tax Dependent"
    when "None"
      "Does not file taxes"
    else
      ""
    end
  end

  def citizen_status(status)
    case status
    when "US"
      "US Citizen"
    when "LP"
      "Lawfully Present"
    when "NLP"
      "Not Lawfully Present"
    else
      ""
    end
  end
end