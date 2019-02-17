module Notifier
  class MergeDataModels::ConsumerRole
    include Virtus.model
    include ActiveModel::Model
    include Notifier::MergeDataModels::TokenBuilder

    attribute :notice_date, String
    attribute :first_name, String
    attribute :last_name, String
    attribute :mailing_address, MergeDataModels::Address
    attribute :age, Integer
    attribute :ivl_oe_start_date, Date
    attribute :ivl_oe_end_date, Date
    attribute :dc_resident, String
    attribute :citizenship, String
    attribute :incarcerated, String
    attribute :other_coverage, String
    attribute :federal_tax_filing_status, String
    attribute :tax_household_size, Integer
    attribute :coverage_year, Integer
    attribute :expected_income_for_coverage_year, Float
    attribute :previous_coverage_year, Integer
    attribute :aptc, Float
    attribute :mec, String
    attribute :actual_income, Float
    attribute :dependents, Array[MergeDataModels::Dependent]
    attribute :addresses, Array[MergeDataModels::Address]

    def self.stubbed_object
      notice = Notifier::MergeDataModels::ConsumerRole.new({
        notice_date: TimeKeeper.date_of_record.strftime('%m/%d/%Y'),
        first_name: 'Samules',
        last_name: 'Parker',
        age: 28,
        dc_resident: 'Yes',
        citizenship: 'US Citizen',
        incarcerated: 'N',
        other_coverage: 'Yes',
        federal_tax_filing_status: 'Married Filing Jointly',
        expected_income_for_coverage_year: 25000.00,
        tax_household_size: 2,
        mec: 'Yes',
        actual_income: 26455.00,
        aptc: 363.23
      })
      #notice.addresses = [ Notifier::MergeDataModels::IvlAddress.stubbed_object ]
      notice.mailing_address = Notifier::MergeDataModels::Address.stubbed_object
      notice.addresses = [notice.mailing_address]
      notice.dependents = [Notifier::MergeDataModels::Dependent.stubbed_object]
      notice
    end

    def is_shop?
      false
    end

    def primary_address
      mailing_address
    end

    def collections
      %w[addresses dependents]
    end

    def conditions
      %w[aqhp_eligible? uqhp_eligible? incarcerated? irs_consent? magi_medicaid? aqhp_or_non_magi_medicaid? uqhp_or_non_magi_medicaid? irs_consent_not_needed? aptc_amount_available? csr? aqhp_eligible_and_irs_consent_not_needed? csr_is_73? csr_is_87? csr_is_94? csr_is_100? csr_is_nil?]
    end

    def aqhp_eligible?
      payload["notice_params"]["primary_member"]["aqhp_eligible"].upcase == "YES"
    end

    def uqhp_eligible?
      payload["notice_params"]["primary_member"]["uqhp_eligible"].upcase == "YES"
    end

    def incarcerated?
      payload["notice_params"]["primary_member"]["incarcerated"].upcase == "N"
    end

    def irs_consent?
      payload["notice_params"]["primary_member"]["irs_consent"].upcase == "YES"
    end

    def magi_medicaid?
      payload["notice_params"]["primary_member"]["magi_medicaid"].upcase == "YES"
    end

    def aqhp_or_non_magi_medicaid?
      aqhp_eligible? || !non_magi_medicaid?
    end

    def uqhp_or_non_magi_medicaid?
      uqhp_eligible? || !non_magi_medicaid?
    end

    def irs_consent_not_needed?
      payload["notice_params"]["primary_member"]["irs_consent"].upcase == "NO"
    end

    def aptc_amount_available?
      payload["notice_params"]["primary_member"]["aptc"].present?
    end

    def csr?
      payload["notice_params"]["primary_member"]["csr"].upcase == "YES"
    end

    def aqhp_eligible_and_irs_consent_not_needed?
      aqhp_eligible? && !irs_consent?
    end

    def csr_is_73?
      false if csr?
      Integer(payload["notice_params"]["primary_member"]["csr_percent"]) == 73
    end

    def csr_is_87?
      false if csr?
      Integer(payload["notice_params"]["primary_member"]["csr_percent"]) == 87
    end

    def csr_is_94?
      false if csr?
      Integer(payload["notice_params"]["primary_member"]["csr_percent"]) == 94
    end

    def csr_is_100?
      false if csr?
      Integer(payload["notice_params"]["primary_member"]["csr_percent"]) == 100
    end

    def csr_is_nil?
      false if csr?
      Integer(payload["notice_params"]["primary_member"]["csr_percent"]) == 0
    end
  end
end
