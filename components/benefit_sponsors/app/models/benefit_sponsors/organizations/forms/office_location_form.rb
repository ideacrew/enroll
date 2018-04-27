module BenefitSponsors
  module Organizations
    class Forms::OfficeLocationForm
      include Virtus.model
      include ActiveModel::Validations

      attribute :is_primary, Boolean
      attribute :address, Forms::AddressForm
      attribute :phone, Forms::PhoneForm

      alias_method :is_primary?, :is_primary

      def persisted?
        false
      end

      def phone_attributes=(phone)
        self.phone = Forms::PhoneForm.new(phone)
      end

      def address_attributes=(address)
        self.address = Forms::AddressForm.new(address)
      end
    end
  end
end
