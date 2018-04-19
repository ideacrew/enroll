module BenefitSponsors
  module Organizations
    class Forms::PhoneForm
      include Virtus.model
      include ActiveModel::Validations

      attribute :kind, String
      attribute :area_code, String
      attribute :number, String
      attribute :extension, String
      validates_presence_of :kind, :area_code, :number, :state, :zip


      def persisted?
        false
      end

    end
  end
end
