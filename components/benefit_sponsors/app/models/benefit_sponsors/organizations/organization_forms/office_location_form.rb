module BenefitSponsors
  module Organizations
    class OrganizationForms::OfficeLocationForm
      include Virtus.model
      include ActiveModel::Validations

      attribute :id, String
      attribute :is_primary, Boolean
      attribute :address, OrganizationForms::AddressForm
      attribute :phone, OrganizationForms::PhoneForm

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
