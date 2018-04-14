module BenefitSponsors
  module Organizations
    class EmployerProfileRegistrationForm
      include ActiveModel::Model
      include ActiveModel::Validations

      attr_accessor :legal_name
      attr_accessor :dba
      attr_accessor :fein
      attr_accessor :entity_kind

      attr_accessor :form_mapping

      def self.for_new(opts = {})
        self.new(
          form_mapping: ::BenefitSponsors::Organizations::EmployerProfileRegistrationFormMapping.new
        )
      end

      def primary_office_location
        @primary_office_location ||= begin
                                       OfficeLocationForm.new(primary: true, form_mapping: form_mapping)
                                     end
      end

      def primary_office_location_attributes
        primary_office_location.attributes
      end

      def primary_office_location_attributes=(params)
        @primary_office_location = OfficeLocationForm.new(params.merge(primary: true, form_mapping: form_mapping))
      end

      def additional_office_locations
        @additional_office_locations ||= begin
                                           [OfficeLocationForm.new(primary: false, form_mapping: form_mapping)]
                                         end
      end

      def additional_office_locations_attributes
        other_office_locations_attributes = {}
        @additional_office_locations.each_with_index do |ol, idx|
          other_office_locations_attributes[idx.to_s] = ol.attributes
        end
        other_office_locations_attributes
      end

      def additional_office_locations_attributes=(params)
        other_office_locations = []
        params.each_pair do |k, ps|
          other_office_locations << OfficeLocationForm.new(ps.merge(primary: false, form_mapping: form_mapping))
        end
        @additional_office_locations = other_office_locations
      end

      def available_entity_kinds
        form_mapping.available_entity_kinds
      end
    end
  end
end
