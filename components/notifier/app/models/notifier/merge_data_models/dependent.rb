module Notifier
  class MergeDataModels::Dependent
    include Virtus.model

    attribute :first_name, String
    attribute :last_name, String
    attribute :age, Integer
    attribute :federal_tax_filing_status, String
    attribute :citizenship, String
    attribute :expected_income_for_coverage_year, String
    attribute :incarcerated, String
    attribute :dc_resident, String
    attribute :other_coverage, String
    attribute :tax_household_size, Integer

    def self.stubbed_object
      Notifier::MergeDataModels::Dependent.new({
        first_name: 'Kristina',
        last_name: 'Parker',
        age: 28,
        federal_tax_filing_status: 'Single',
        expected_income_for_coverage_year: 250.00,
        citizenship: 'US Citizen',
        dc_resident: 'Yes',
        other_coverage: 'Yes',
        tax_household_size: '3',
        incarcerated: 'No' 
      })
    end
  end
end
