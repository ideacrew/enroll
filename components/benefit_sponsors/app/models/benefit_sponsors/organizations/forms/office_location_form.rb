module BenefitSponsors
  module Organizations
    class Forms::OfficeLocationForm
      include Virtus.model
      include ActiveModel::Validations

      attribute :is_primary, Boolean
      attribute :address, Forms::AddressForm
      attribute :phone, Forms::PhoneForm
    end
  end
end
