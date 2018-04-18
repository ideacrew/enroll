module BenefitSponsors
  module Services
    class NewProfileRegistrationService

      attr_reader :organization, :profile, :representative

      def initialize(params)
        @organization   = params[:organization]
        @profile        = params[:profile]
        @representative = params[:representative]
      end

      # Serialized model attributes, plus form metadata
      def build
        objects = build_classes

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

      private

      def build_classes
        @organization = BenefitSponsors::Organizations::Factories::ProfileFactory.build_organization
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
