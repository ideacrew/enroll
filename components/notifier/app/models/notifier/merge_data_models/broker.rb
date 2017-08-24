module Notifier
  class MergeDataModels::Broker
    include Virtus.model

    attribute :primary_fullname, String, default: 'Count Olaf'
    attribute :organization, String, default: 'Sony'
    attribute :address, MergeDataModels::Address
    attribute :phone, String, default: '000-000-0007'
    attribute :email, String, default: 'count.olaf@unfortunate.org'
    attribute :web_address, String, default: 'http://unfortunate.events.org'
  end
end
