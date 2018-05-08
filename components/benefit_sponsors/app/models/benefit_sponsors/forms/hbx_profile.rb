module BenefitSponsors
  module Forms
    class HbxProfile
      extend ActiveModel::Naming

      include ActiveModel::Conversion
      include ActiveModel::Model
      include ActiveModel::Validations

      include Virtus.model

      attribute :id, String
      attribute :office_locations, [BenefitSponsors::Organizations::Forms::OfficeLocationForm]

      def primary_office_location
        office_locations.find(&:is_primary?)
      end

      def other_office_locations
        office_locations.reject(&:is_primary?)
      end

      def office_locations_attributes=(office_locations)
        self.office_locations = office_locations.map do |key, office_location|
          BenefitSponsors::Organizations::Forms::OfficeLocationForm.new office_location
        end
      end
    end
  end
end
