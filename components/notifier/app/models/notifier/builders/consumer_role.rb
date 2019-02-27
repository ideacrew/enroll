module Notifier
  class Builders::ConsumerRole

    include ActionView::Helpers::NumberHelper
    include Notifier::ApplicationHelper
    include Config::ContactCenterHelper
    include Config::SiteHelper

    attr_accessor :consumer_role, :merge_model, :full_name, :payload, :event_name, :sep_id

    def initialize
      data_object = Notifier::MergeDataModels::ConsumerRole.new
      data_object.mailing_address = Notifier::MergeDataModels::Address.new
      @merge_model = data_object
    end

    def resource=(resource)
      @consumer_role = resource
    end

    def notice_date
      merge_model.notice_date = TimeKeeper.date_of_record.strftime('%B %d, %Y')
    end

    def first_name
      merge_model.first_name = consumer_role.person.first_name if consumer_role.present?
    end

    def last_name
      merge_model.last_name = consumer_role.person.last_name if consumer_role.present?
    end

    def primary_fullname
      merge_model.primary_fullname = consumer_role.person.full_name.titleize if consumer_role.present?
    end

    def aptc
      merge_model.aptc = (payload['notice_params']['primary_member']['aptc'])
    end

    def other_coverage
      merge_model.other_coverage = payload['notice_params']['primary_member']['mec'].present? ? payload['notice_params']['primary_member']['mec'] : 'No'
    end

    def age
      merge_model.age = Date.current.year - Date.parse(payload['notice_params']['primary_member']['dob']).year
    end

    def person
      consumer_role.person
    end

    def append_contact_details
      mailing_address = consumer_role.person.mailing_address
      if mailing_address.present?
        merge_model.mailing_address = MergeDataModels::Address.new({
          street_1: mailing_address.address_1,
          street_2: mailing_address.address_2,
          city: mailing_address.city,
          state: mailing_address.state,
          zip: mailing_address.zip
          })
      end
    end

    def dependents
      payload["notice_params"]["dependents"].each do |member|
        merge_model.dependents << MergeDataModels::Dependent.new({
          first_name: member["first_name"],
          last_name: member["last_name"],
          age: Date.current.year - Date.parse(member["dob"]).year,
          federal_tax_filing_status: filer_type(member["filer_type"]),
          expected_income_for_coverage_year: member["actual_income"].present? ? ActionController::Base.helpers.number_to_currency(member['actual_income'], :precision => 0) : "",
          citizenship: citizen_status(member["citizen_status"]),
          dc_resident: member["resident"],
          tax_household_size: member["tax_hh_count"],
          incarcerated: (member['incarcerated'] == "N") ? "No" : "Yes",
          other_coverage: member["mec"].present? ? member["mec"] : "No",
          aptc: member["aptc"],
          aqhp_eligible: member["aqhp_eligible"].upcase == "YES",
          uqhp_eligible: member["uqhp_eligible"].upcase == "YES",
          totally_ineligible: member["totally_inelig"].upcase == "YES"
        })
      end
    end

    def ivl_oe_start_date
      merge_model.ivl_oe_start_date = Settings.aca.individual_market.upcoming_open_enrollment.start_on.strftime('%B %d, %Y')
    end

    def ivl_oe_end_date
      merge_model.ivl_oe_end_date = Settings.aca.individual_market.upcoming_open_enrollment.end_on.strftime('%B %d, %Y')
    end

    def coverage_year
      merge_model.coverage_year = TimeKeeper.date_of_record.next_year.year
    end

    def previous_coverage_year
      merge_model.previous_coverage_year = coverage_year.to_i - 1
    end

    def dc_resident
      merge_model.dc_resident = payload['notice_params']['primary_member']['resident'].capitalize
    end

    def expected_income_for_coverage_year
      merge_model.expected_income_for_coverage_year = payload['notice_params']['primary_member']['actual_income'].present? ? ActionController::Base.helpers.number_to_currency(payload['notice_params']['primary_member']['actual_income'], :precision => 0) : ""
    end

    def federal_tax_filing_status
      merge_model.federal_tax_filing_status = filer_type(payload['notice_params']['primary_member']['filer_type'])
    end

    def citizenship
      merge_model.citizenship = citizen_status(payload['notice_params']['primary_member']['citizen_status'])
    end

    def tax_household_size
      merge_model.tax_household_size = Integer(payload['notice_params']['primary_member']['tax_hh_count'])
    end

    def actual_income
      merge_model.actual_income = Integer(payload['notice_params']['primary_member']['actual_income'])
    end

    def aqhp_eligible
      merge_model.aqhp_eligible = payload['notice_params']['primary_member']['aqhp_eligible'].upcase == "YES"
    end

    def totally_ineligible
      merge_model.aqhp_eligible = payload['notice_params']['primary_member']['totally_inelig'].upcase == "YES"
    end

    def uqhp_eligible
      merge_model.uqhp_eligible = payload['notice_params']['primary_member']['uqhp_eligible'].upcase == "YES"
    end

    def incarcerated
      merge_model.incarcerated = (payload['notice_params']['primary_member']['incarcerated'] == "N") ? "No" : "Yes"
    end

    def irs_consent
      merge_model.irs_consent = payload['notice_params']['primary_member']['irs_consent'].upcase == "YES"
    end

    def magi_medicaid
      merge_model.magi_medicaid = payload['notice_params']['primary_member']['magi_medicaid'].upcase == "YES"
    end

    def non_magi_medicaid
      merge_model.non_magi_medicaid = payload['notice_params']['primary_member']['non_magi_medicaid'].upcase == "YES"
    end

    def csr
      merge_model.csr = payload['notice_params']['primary_member']['csr'].upcase == "YES"
    end

    def csr_percent
      merge_model.csr_percent = Integer(payload['notice_params']['primary_member']['csr_percent'])
    end

    def format_date(date)
      return '' if date.blank?
      date.strftime('%B %d, %Y')
    end

    def depents
      true
    end

    def aqhp_eligible?
      aqhp_eligible
    end

    def totally_ineligible?
      totally_ineligible
    end

    def uqhp_eligible?
      uqhp_eligible
    end

    def incarcerated?
      incarcerated.upcase == "No"
    end

    def irs_consent?
      irs_consent
    end

    def magi_medicaid?
      magi_medicaid
    end

    def non_magi_medicaid?
      non_magi_medicaid
    end

    def aptc_is_zero?
      aptc.present? && aptc.to_i.zero?
    end

    def aqhp_or_non_magi_medicaid?
      aqhp_eligible? || !non_magi_medicaid?
    end

    def uqhp_or_non_magi_medicaid?
      uqhp_eligible? || !non_magi_medicaid?
    end

    def irs_consent_not_needed?
      !irs_consent
    end

    def aptc_amount_available?
      aptc.present?
    end

    def csr?
      csr
    end

    def aqhp_eligible_and_irs_consent_not_needed?
      aqhp_eligible? && !irs_consent?
    end

    def csr_is_73?
      false unless csr?
      csr_percent == 73
    end

    def csr_is_87?
      false unless csr?
      csr_percent == 87
    end

    def csr_is_94?
      false unless csr?
      csr_percent == 94
    end

    def csr_is_100?
      false unless csr?
      csr_percent == 100
    end

    def csr_is_zero?
      false unless csr?
      csr_percent == 0
    end

    def csr_is_nil?
      false unless csr?
    end

    def shop?
      false
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
end
