module BenefitSponsors
  module Organizations
    class Forms::OfficeLocationForm
      include Virtus.model
      include ActiveModel::Validations

      attribute :is_primary, Boolean
      attribute :address, Forms::AddressForm
      attribute :phone, Forms::PhoneForm

      def persisted?
        false
      end

      def phone_attributes=(phone)
      end

      def address_attributes=(address)
      end
    end
  end
end
