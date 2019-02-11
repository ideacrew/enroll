module Notifier
  class MergeDataModels::ConsumerRole
    include Virtus.model
    include ActiveModel::Model
    include Notifier::MergeDataModels::TokenBuilder

    attribute :notice_date, String
    attribute :first_name, String
    attribute :last_name, String
    attribute :primary_fullname, String
    attribute :mailing_address, MergeDataModels::IvlAddress
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
    attribute :coverage_year, Integer
    attribute :previous_coverage_year, Integer
    attribute :expected_income_for_coverage_year, String
    attribute :aqhp, Boolean
    attribute :irs_consent, Boolean
    attribute :dependents, Array[MergeDataModels::Dependent]
    attribute :addresses, Array[MergeDataModels::IvlAddress]

    def self.stubbed_object
      notice = Notifier::MergeDataModels::ConsumerRole.new({
        notice_date: TimeKeeper.date_of_record.strftime('%m/%d/%Y'),
        first_name: 'Samules',
        last_name: 'Parker',
        primary_fullname: 'Samules Parker',
        age: 28,
        email: 'johnwhitmore@yahoo.com',
        ivl_oe_start_date: Settings.aca.individual_market.upcoming_open_enrollment.start_on,
        ivl_oe_end_date: Settings.aca.individual_market.upcoming_open_enrollment.end_on,
        dc_resident: 'Yes',
        citizenship: 'US Citizen',
        incarcerated: 'No',
        other_coverage: 'Yes',
        federal_tax_filing_status: 'Single',
        expected_income_for_coverage_year: 250.00,
        tax_household_size: 3,
        coverage_year: 2019,
        previous_coverage_year: 2018,
        aqhp: true,
        irs_consent: true
      })
      #notice.addresses = [ Notifier::MergeDataModels::IvlAddress.stubbed_object ]
      notice.mailing_address = Notifier::MergeDataModels::IvlAddress.stubbed_object
      notice.addresses = [ notice.mailing_address ]
      notice.dependents = [ Notifier::MergeDataModels::Dependent.stubbed_object ]
      notice
    end

    def shop?
      false
    end

    def primary_address
      mailing_address
    end

    def collections
      %w{addresses dependents}
    end

    def conditions
      %w{aqhp? irs_consent?}
    end

    def aqhp?
        self.aqhp
    end

    def irs_consent?
        self.irs_consent
    end
  end
end
