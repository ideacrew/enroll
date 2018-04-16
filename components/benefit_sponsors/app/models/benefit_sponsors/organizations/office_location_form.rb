module BenefitSponsors
  module Organizations
    class OfficeLocationForm
      include ActiveModel::Model
      include ActiveModel::Validations

      attr_accessor :address_1
      attr_accessor :address_2
      attr_accessor :city
      attr_accessor :state
      attr_accessor :zip

      attr_accessor :primary

      attr_accessor :country_code
      attr_accessor :area_code
      attr_accessor :number
      attr_accessor :extension

      attr_accessor :form_mapping

      def available_states
        form_mapping.available_states
      end
    end
  end
end
