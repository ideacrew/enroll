module BenefitSponsors
  module Services
    class NewProfileRegistrationService

      attr_reader :organization, :profile, :representative
      attr_accessor :profile_type

      def initialize(attrs)
        @profile_type = attrs[:profile_type]
      end

      # Serialized model attributes, plus form metadata
      def self.build(attrs)
        factory_obj = new(attrs)
        factory_obj.send(:build_classes, profile_type)
      end

      def params_to_attributes(params)

      end

      def attributes_to_params(klass)

      end

      # List of required fields, select option arrays
      def form_metadata

      end

      def store!
        match_or_create_organization
        match_or_create_representative
        create_profile

        publish_event

        self
      end

      def self.office_kind_options
      end

      private

      def build_classes(profile_type)
        @organization = BenefitSponsors::Organizations::Factories::ProfileFactory.build({profile_type: profile_type})
        # deal with person
        
        attributes_to_params
      end

      def entity_kind_options
      end

      def match_or_create_organization

        @organization = BenefitSponsors::Organizations::Organization.new
      end

      def match_or_create_representative
      end

      def create_profile
      end

      def publish_event
      end

    end
  end
end
