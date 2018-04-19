module BenefitSponsors
  module Organizations
    class Forms::PhoneForm
      include Virtus.model
      include ActiveModel::Validations

      attribute :kind, String
      attribute :area_code, String
      attribute :number, String

      def self.office_kind_options
        Services::NewProfileRegistrationService.office_kind_options
      end
      

      validates_presence_of :kind, :area_code, :number, :state, :zip
      validates :kind,
        inclusion: { in: office_kind_options, message: "%{value} is not a valid phone type" },
        allow_blank: false

    end
  end
end
