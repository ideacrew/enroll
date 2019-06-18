# frozen_string_literal: true

module FinancialAssistance
  module Forms
    class AddressForm
      include Virtus.model

      attribute :id, String
      attribute :address_1, String
      attribute :address_2, String
      attribute :city, String
      attribute :state, String
      attribute :zip, String

    end
  end
end
