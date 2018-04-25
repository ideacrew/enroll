module BenefitSponsors
  module Organizations
    class Forms::OfficeLocationForm
      include Virtus.model
      include ActiveModel::Validations

      attribute :id, String
      attribute :is_primary, Boolean
      attribute :address, Forms::AddressForm
      attribute :phone, Forms::PhoneForm

      def persisted?
        false
      end

      def phone_attributes=(phone_params)
        self.phone = phone_params
      end

      def address_attributes=(address_params)
        self.address = address_params 
      end
    end
  end
end
