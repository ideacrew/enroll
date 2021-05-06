module Notifier
  class MergeDataModels::Address
    include Virtus.model

    attribute :street_1, String
    attribute :street_2, String
    attribute :city, String
    attribute :state, String
    attribute :zip, String

    def self.stubbed_object
      Notifier::MergeDataModels::Address.new({street_1: '1225 I Street, NW',
                                              street_2: 'Suite 400',
                                              city: Settings.notices.individual_market.mail_address.city,
                                              state: Settings.aca.state_abbreviation,
                                              zip: Settings.notices.shop_market.mail_address.zip_code})
    end
  end
end
