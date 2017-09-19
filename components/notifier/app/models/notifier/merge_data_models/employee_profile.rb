module Notifier
  class MergeDataModels::EmployeeProfile
    include Virtus.model
    include ActiveModel::Model
    include Notifier::MergeDataModels::TokenBuilder

    attribute :notice_date, Date, default: TimeKeeper.date_of_record.strftime('%m/%d/%Y')
    attribute :first_name, String, default: 'John'
    attribute :last_name, String, default: 'Whitmore'
    attribute :mailing_address, MergeDataModels::Address
    attribute :ivl_sep_begin_date, Date, default: TimeKeeper.date_of_record.strftime('%m/%d/%Y')
    attribute :ivl_sep_end_date, Date, default: (TimeKeeper.date_of_record + 60.days).strftime('%m/%d/%Y')
    attribute :employer_name, String, default: 'MA Health Connector'
    attribute :coverage_begin_date, Date, default: TimeKeeper.date_of_record.strftime('%m/%d/%Y')
    attribute :broker, MergeDataModels::Broker

    attribute :date_of_hire, Date, default: TimeKeeper.date_of_record.strftime('%m/%d/%Y') 
    attribute :earliest_coverage_begin_date, Date, default: TimeKeeper.date_of_record.next_month.beginning_of_month.strftime('%m/%d/%Y')
    attribute :new_hire_oe_end_date, Date, default: (TimeKeeper.date_of_record + 30.days).strftime('%m/%d/%Y')
    attribute :addresses, Array[MergeDataModels::Address]

  
    def self.stubbed_object
      notice = Notifier::MergeDataModels::EmployeeProfile.new
      notice.mailing_address = Notifier::MergeDataModels::Address.new
      notice.broker = Notifier::MergeDataModels::Broker.new
      notice.addresses = [ notice.mailing_address ]
      notice
    end

    def collections
      []
    end

    def conditions
      %w{broker_present?}
    end

    def broker_present?
      self.broker.present?
    end
  end
end