module Notifier
  class Builders::ConsumerRole

    include ActionView::Helpers::NumberHelper
    include Notifier::ApplicationHelper
    include Config::ContactCenterHelper
    include Config::SiteHelper
    #include Notifier::Builders::Dependent

    attr_accessor :consumer_role, :merge_model, :payload, :event_name, :sep_id

    def initialize
      data_object = Notifier::MergeDataModels::ConsumerRole.new
      data_object.mailing_address = Notifier::MergeDataModels::Address.new
      data_object.dependents = Notifier::MergeDataModels::Dependent.new
      @merge_model = data_object
    end

    def resource=(resource)
      @consumer_role = resource
    end

    def notice_date
      merge_model.notice_date = TimeKeeper.date_of_record.strftime('%m/%d/%Y')
    end

    def first_name
      merge_model.first_name = consumer_role.person.first_name if consumer_role.present?
    end

    def last_name
      merge_model.last_name = consumer_role.person.last_name if consumer_role.present?
    end

    def aptc
      merge_model.aptc = payload['notice_params']['primary_member']['aptc'] if payload['notice_params']['primary_member']['aptc'].present?
    end

    def age
      Date.current.year - Date.parse(payload['notice_params']['primary_member']['dob']).year
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
          federal_tax_filing_status: member["federal_tax_filing_status"],
          expected_income_for_coverage_year: member["expected_income_for_coverage_year"],
          citizenship: member["citizenship"],
          dc_resident: member["dc_resident"],
          tax_household_size: member["tax_household_size"],
          incarcerated: member["incarcerated"],
          mec: member["mec"],
          actual_income: member["actual_income"],
          aptc: member["aptc"],
          uqhp_eligible: member["uqhp_eligible"].upcase == "YES"
        })
      end
    end

    def dependent_first_name
      "sdsf"
    end

    def ivl_oe_start_date
      merge_model.ivl_oe_start_date = Settings.aca.individual_market.upcoming_open_enrollment.start_on
    end

    def ivl_oe_end_date
      merge_model.ivl_oe_end_date = Settings.aca.individual_market.upcoming_open_enrollment.end_on
    end

    # def email
    #   merge_model.email = consumer_role.person.work_email_or_best if consumer_role.present?
    # end

    def coverage_year
      TimeKeeper.date_of_record.next_year.year
    end

    def previous_coverage_year
      coverage_year.to_i - 1
    end

    def aqhp_eligible
      payload['notice_params']['primary_member']['aqhp_eligible'].upcase == "YES"
    end

    def uqhp_eligible
      payload['notice_params']['primary_member']['uqhp_eligible'].upcase == "YES"
    end

    def incarcerated
      payload['notice_params']['primary_member']['incarcerated'].upcase == "N"
    end

    def irs_consent
      payload['notice_params']['primary_member']['irs_consent'].upcase == "YES"
    end

    def magi_medicaid
      payload['notice_params']['primary_member']['magi_medicaid'].upcase == "YES"
    end

    # def aptc_amount_available
    #   payload['notice_params']['primary_member']['aptc'].present?
    # end

    def csr
      payload['notice_params']['primary_member']['csr'].upcase == "YES"
    end

    def csr_percent
      Integer(payload['notice_params']['primary_member']['csr_percent'])
    end

     # Using same merge model for special enrollment period and qualifying life event kind
    def format_date(date)
      return '' if date.blank?
      date.strftime('%m/%d/%Y')
    end

    def aqhp_eligible?
      aqhp_eligible
    end

    def uqhp_eligible?
      uqhp_eligible
    end

    def incarcerated?
      incarcerated
    end

    def irs_consent?
      irs_consent
    end

    def magi_medicaid?
      magi_medicaid
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
      false if csr?
      csr_percent == 73
    end

    def csr_is_87?
      false if csr?
      csr_percent == 87
    end

    def csr_is_94?
      false if csr?
      csr_percent == 94
    end

    def csr_is_100?
      false if csr?
      csr_percent == 100
    end

    def csr_is_nil?
      false if csr?
      csr_percent == 0
    end

    def is_shop?
      false
    end
  end
end
