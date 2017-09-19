module Notifier
  class MergeDataModels::BrokerProfile

    include Virtus.model
    include ActiveModel::Model
    include Notifier::MergeDataModels::TokenBuilder

    attribute :notice_date, Date, default: TimeKeeper.date_of_record.strftime('%m/%d/%Y')
    attribute :first_name, String, default: 'John'
    attribute :last_name, String, default: 'Whitmore'
    attribute :mailing_address, MergeDataModels::Address

    attribute :borker_agency_name, String, default: 'Best Brokers LLC'
    attribute :assignment_date, Date, default: TimeKeeper.date_of_record.strftime('%m/%d/%Y') 
    attribute :employer_name, String, default: 'North America Football Federation'
    attribute :employer_poc_firstname, String, default: 'David'
    attribute :employer_poc_lastname, String, default: 'Samules'


    def collections
      []
    end

    def conditions
      []
    end
  end
end