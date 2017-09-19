module Notifier
  class MergeDataModels::Broker
    include Virtus.model

    attribute :primary_fullname, String, default: 'Count Olaf'
    attribute :organization, String, default: 'Best Brokers LLC'
    attribute :address, MergeDataModels::Address
    attribute :phone, String, default: '703-303-1007'
    attribute :email, String, default: 'count.olaf@bestbrokers.llc'
    attribute :web_address, String, default: 'http://bestbrokers.llc'
  end
end
