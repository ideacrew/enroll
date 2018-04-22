module BenefitSponsors
  module Services
    class NewProfileRegistrationService

      attr_reader :organization, :profile, :representative
      attr_accessor :profile_type, :profile_id

      def initialize(attrs={})
        @profile_type = attrs[:profile_type]
        @profile_id = attrs[:profile_id]
      end

      def build(attrs)
        factory_class = BenefitSponsors::Organizations::Factories::ProfileFactory
        organization = factory_class.build(attrs)
        staff_roles = factory_class.find_representatives(profile_id)
        attributes_to_form_params(organization)
      end

      def find(profile_id)
        factory_class = BenefitSponsors::Organizations::Factories::ProfileFactory
        organization = factory_class.build(profile_id)
        staff_roles = factory_class.find_representatives(profile_id)
        attributes_to_form_params(organization, staff_roles)
      end

      def attributes_to_form_params(organization_obj, staff_roles=nil)
        {
          :"profile_type" => profile_type,
          :"profile_id" => profile_id,
          :"staff_roles" => staff_role_params(staff_roles),
          :"organization" => Serializers::OrganizationSerializer.new(organization_obj).to_hash
        }
      end


      def staff_role_params(staff_roles)
        return [{}] if staff_roles.blank?
        staff_roles.inject([]) do |result, role|
          result << Serializers::StaffRoleSerializer.new(role).to_hash
          result
        end
      end

      # Serialized model attributes, plus form metadata
      def self.build(attrs)
        factory_obj = new(attrs)
        factory_obj.send(:build_classes, profile_type)
      end

      # TODO

      def save(attrs, current_user=nil)
        persist_from_factory(attrs, current_user)
      end

      def update(attrs)
        update_from_factory(attrs)
      end

      def persist_from_factory(attrs, current_user)
        Organizations::Factories::ProfileFactory.call_persist(attrs, current_user)
      end

      def update_from_factory(attrs)
        Organizations::Factories::ProfileFactory.call_update(attrs, profile_id)
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
