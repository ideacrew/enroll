module BenefitSponsors
  module Organizations
    class Forms::AddressForm
      include Virtus.model
      include ActiveModel::Validations

      attribute :address_1, String
      attribute :address_2, String
      attribute :city, String
      attribute :state, String
      attribute :zip, String

      validates_presence_of :address_1, :city, :state, :zip
    end
  end
end
