class IvlNotices::FinalEligibilityNotice < IvlNotice
  include ApplicationHelper
  attr_accessor :family, :data, :person, :open_enrollment_start_on, :open_enrollment_end_on

  def initialize(consumer_role, args = {})
    args[:recipient] = consumer_role.person.families.first.primary_applicant.person
    args[:notice] = PdfTemplates::ConditionalEligibilityNotice.new
    args[:market_kind] = 'individual'
    args[:recipient_document_store]= consumer_role.person.families.first.primary_applicant.person
    args[:to] = consumer_role.person.families.first.primary_applicant.person.work_email_or_best
    self.person = args[:person]
    self.open_enrollment_start_on = args[:open_enrollment_start_on]
    self.open_enrollment_end_on = args[:open_enrollment_end_on]
    self.data = args[:data]
    self.header = "notices/shared/header_ivl.html.erb"
    super(args)
  end

  def deliver
    build
    generate_pdf_notice
    attach_blank_page(notice_path)
    attach_required_documents if notice.documents_needed
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

  def build
    notice.notification_type = self.event_name
    notice.mpi_indicator = self.mpi_indicator
    notice.primary_identifier = recipient.hbx_id
    notice.coverage_year = TimeKeeper.date_of_record.next_year.year
    notice.current_year = TimeKeeper.date_of_record.year
    notice.ivl_open_enrollment_start_on = open_enrollment_start_on
    notice.ivl_open_enrollment_end_on = open_enrollment_end_on
    append_data
    append_hbe
    notice.primary_fullname = person.full_name.titleize || ""
    if recipient.mailing_address
      append_address(recipient.mailing_address)
    else
      # @notice.primary_address = nil
      raise 'mailing address not present'
    end
  end

  def append_data
    primary_member = data.detect{|m| m["subscriber"].upcase == "YES"}
    append_member_information_for_aqhp(primary_member)
    pick_enrollments
    if primary_member["aqhp_eligible"].upcase == "YES"
      notice.tax_households = append_tax_household_information(primary_member)
    end
    notice.documents_needed = check(primary_member["documents_needed"])
    notice.has_applied_for_assistance = check(primary_member["aqhp_eligible"])
    notice.irs_consent_needed = check(primary_member["irs_consent"])
    notice.primary_firstname = primary_member["first_name"]
  end

  def append_member_information_for_aqhp(primary_member)
    due_dates = []
    data.collect do |datum|
      notice.individuals << PdfTemplates::Individual.new({
        :first_name => datum["first_name"].titleize,
        :last_name => datum["last_name"].titleize,
        :full_name => datum["full_name"].titleize,
        :age => calculate_age_by_dob(Date.strptime(datum["dob"], '%m/%d/%Y')),
        :incarcerated => datum["incarcerated"].upcase == "N" ? "No" : "Yes",
        :citizen_status => citizen_status(datum["citizen_status"]),
        :residency_verified => datum["resident"].upcase == "YES"  ? "Yes" : "No",
        :actual_income => datum["actual_income"],
        :taxhh_count => datum["tax_hh_count"],
        :tax_status => filer_type(datum["filer_type"]),
        :mec => datum["mec"].try(:upcase) == "YES" ? "Yes" : "No",
        :is_ia_eligible => check(datum["aqhp_eligible"]),
        :is_medicaid_chip_eligible => check(datum["magi_medicaid"]),
        :is_non_magi_medicaid_eligible => check(datum["non_magi_medicaid"]),
        :is_without_assistance => check(datum["uqhp_eligible"]),
        :is_totally_ineligible => check(datum["totally_inelig"]),
        :magi_medicaid_monthly_income_limit => datum["medicaid_monthly_income_limit"],
        :has_access_to_affordable_coverage => check(datum ["mec"]),
        :tax_household => append_tax_household_information(primary_member)
      })

      due_dates << Date.strptime(datum["document_deadline"], '%m/%d/%Y')

      if datum["outstanding_verification_types"].include?("Social Security Number")
        notice.ssa_unverified << PdfTemplates::Individual.new({ full_name: datum["first_name"].titleize, documents_due_date: Date.strptime(datum["document_deadline"], '%m/%d/%Y'), age: calculate_age_by_dob(Date.strptime(datum["dob"], '%m/%d/%Y')) })
      end
      if datum["outstanding_verification_types"].include?("Immigration status")
        notice.dhs_unverified << PdfTemplates::Individual.new({ full_name: datum["first_name"].titleize, documents_due_date: Date.strptime(datum["document_deadline"], '%m/%d/%Y'), age: calculate_age_by_dob(Date.strptime(datum["dob"], '%m/%d/%Y')) })
      end
      if datum["outstanding_verification_types"].include?("Citizenship")
        notice.citizenstatus_unverified << PdfTemplates::Individual.new({ full_name: datum["first_name"].titleize, documents_due_date: Date.strptime(datum["document_deadline"], '%m/%d/%Y'), age: calculate_age_by_dob(Date.strptime(datum["dob"], '%m/%d/%Y')) })
      end
    end
    notice.due_date = due_dates.min
  end

  def pick_enrollments
    hbx_enrollments = []
    family = recipient.primary_family
    enrollments = family.enrollments.where(:aasm_state => "auto_renewing", :kind => "individual")
    return nil if enrollments.blank?
    health_enrollments = enrollments.select{ |e| e.coverage_kind == "health" && e.effective_on.year == 2018}
    dental_enrollments = enrollments.select{ |e| e.coverage_kind == "dental" && e.effective_on.year == 2018}

    hbx_enrollments << health_enrollments
    hbx_enrollments << dental_enrollments

    return nil if hbx_enrollments.flatten.compact.empty?
    hbx_enrollments.flatten.compact.each do |enrollment|
      notice.enrollments << append_enrollment_information(enrollment)
    end
  end

  def append_enrollment_information(enrollment)
    plan = PdfTemplates::Plan.new({
      plan_name: enrollment.plan.name,
      is_csr: enrollment.plan.is_csr?,
      coverage_kind: enrollment.plan.coverage_kind,
      plan_carrier: enrollment.plan.carrier_profile.organization.legal_name,
      family_deductible: enrollment.plan.family_deductible.split("|").last.squish,
      deductible: enrollment.plan.deductible
      })
    PdfTemplates::Enrollment.new({
      premium: enrollment.total_premium.round(2),
      aptc_amount: enrollment.applied_aptc_amount.round(2),
      responsible_amount: (enrollment.total_premium - enrollment.applied_aptc_amount.to_f).round(2),
      phone: phone_number(enrollment.plan.carrier_profile.legal_name),
      is_receiving_assistance: (enrollment.applied_aptc_amount > 0 || enrollment.plan.is_csr?) ? true : false,
      coverage_kind: enrollment.coverage_kind,
      kind: enrollment.kind,
      effective_on: enrollment.effective_on,
      plan: plan,
      enrollees: enrollment.hbx_enrollment_members.inject([]) do |enrollees, member|
        enrollee = PdfTemplates::Individual.new({
          full_name: member.person.full_name.titleize,
          age: member.person.age_on(TimeKeeper.date_of_record)
        })
        enrollees << enrollee
      end
    })
  end

  def phone_number(legal_name)
    case legal_name
    when "BestLife"
      "(800) 433-0088"
    when "CareFirst"
      "(855) 444-3119"
    when "Delta Dental"
      "(800) 471-0236"
    when "Dominion"
      "(855) 224-3016"
    when "Kaiser"
      "(844) 524-7370"
    end
  end

  def append_tax_household_information(primary_member)
    PdfTemplates::TaxHousehold.new({
      :csr_percent_as_integer => (primary_member["csr"].upcase == "YES") ? primary_member["csr_percent"] : "100",
      :max_aptc => primary_member["aptc"],
      :aptc_csr_annual_household_income => primary_member["actual_income"],
      :aptc_annual_income_limit => primary_member["aptc_annual_limit"],
      :csr_annual_income_limit => primary_member["csr_annual_income_limit"]
    })
  end

  def filer_type(type)
    case type
    when "Filers"
      "Tax Filer"
    when "Dependents"
      "Tax Dependent"
    when "Married Filing Jointly"
      "Married Filing Jointly"
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
    when "NC"
      "US Citizen"
    else
      ""
    end
  end

end