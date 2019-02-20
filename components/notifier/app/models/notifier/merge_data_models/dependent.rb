module Notifier
  class MergeDataModels::Dependent
    include Virtus.model

    attribute :first_name, String
    attribute :last_name, String
    attribute :mailing_address, MergeDataModels::Address
    attribute :age, Integer
    attribute :dc_resident, String
    attribute :citizenship, String
    attribute :incarcerated, String
    attribute :federal_tax_filing_status, String
    attribute :tax_household_size, Integer
    attribute :expected_income_for_coverage_year, Float
    attribute :aptc, Float
    attribute :mec, String
    attribute :actual_income, Float
    attribute :uqhp_eligible, Boolean

    def self.stubbed_object
      Notifier::MergeDataModels::Dependent.new({
        first_name: 'Kristina',
        last_name: 'Parker',
        age: 28,
        federal_tax_filing_status: 'Married Filing Jointly',
        expected_income_for_coverage_year: 35000.00,
        citizenship: 'US Citizen',
        dc_resident: 'Yes',
        tax_household_size: 2,
        incarcerated: 'N',
        mec: 'Yes',
        actual_income: 25450.00,
        aptc: 363.23,
        uqhp_eligible: true
      })
    end

    def collections
      %w[]
    end

    def conditions
      %w[uqhp_eligible? uqhp_ineligible?]
    end

    def uqhp_eligible?
      uqhp_eligible
    end

    def uqhp_ineligible?
      !uqhp_eligible
    end
  end
end