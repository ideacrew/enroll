class IvlNotices::FinalEligibilityNoticeAqhp < IvlNotice
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
    notice.coverage_year = TimeKeeper.date_of_record.next_year.year
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
    primary_member = data.detect{|m| m["subscriber"] == "Yes"}
    append_enrollment_information
    append_member_information(primary_member)
    if primary_member["aqhp_eligible"].upcase == "YES"
      notice.tax_households = append_tax_household_information(primary_member)
    end
    notice.documents_needed = check(primary_member("documents_needed"))
    notice.has_applied_for_assistance = check(primary_member["aqhp_eligible"])
    notice.irs_consent_needed = check(primary_member["irs_consent"])
    notice.primary_firstname = primary_member["first_name"]
  end

  def append_member_information(primary_member)
    notice.individuals = data.collect do |datum|
      PdfTemplates::Individual.new({
        :first_name => datum["first_name"],
        :last_name => datum["last_name"],
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
    end
  end

  def append_enrollment_information

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