module Notifier
  class MergeDataModels::Address
    include Virtus.model

    attribute :street_1, String, default: '330 Montague City Road'
    attribute :street_2, String, default: 'Suite 200'
    attribute :city, String, default: 'Turners Falls'
    attribute :state, String, default: 'MA'
    attribute :zip, String, default: '01373'
  end
end
