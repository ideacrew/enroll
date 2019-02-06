module Notifier
  class MergeDataModels::ConsumerProfile
    include Virtus.model
    include ActiveModel::Model
    include Notifier::MergeDataModels::TokenBuilder

    attribute :notice_date, String
    attribute :first_name, String
    attribute :last_name, String
    attribute :address, MergeDataModels::IvlAddress
    attribute :email, String
    attribute :age, Integer
    attribute :ivl_oe_start_date, Date
    attribute :ivl_oe_end_date, Date
    attribute :dc_resident, String
    attribute :citizenship, String
    attribute :incarcerated, String
    attribute :other_coverage, String
    attribute :federal_tax_filing_status, String
    attribute :tax_household_size, Integer
    attribute :expected_income_for_coverage_year, String
    attribute :dependents, Array[MergeDataModels::Dependent]

    def self.stubbed_object
      notice = Notifier::MergeDataModels::Dependent.new({
        notice_date: TimeKeeper.date_of_record.strftime('%m/%d/%Y'),
        first_name: 'Samules',
        last_name: 'Parker',
        age: 28,
        federal_tax_filing_status: 'Single',
        expected_income_for_coverage_year: 250.00,
        dc_resident: 'Yes',
        other_coverage: 'Yes',
        email: 'johnwhitmore@yahoo.com',
        ivl_oe_start_date: Settings.aca.individual_market.upcoming_open_enrollment.start_on,
        ivl_oe_end_date: Settings.aca.individual_market.upcoming_open_enrollment.end_on,
        citizenship: 'US Citizen',
        incarcerated: 'No',
        other_coverage: 'Yes',
        tax_household_size: '3'
      })
      #notice.addresses = [Notifier::MergeDataModels::IvlAddress.stubbed_object]
      notice.dependents = [Notifier::MergeDataModels::Dependent.stubbed_object]
      notice
    end
  end
end