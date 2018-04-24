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

      def attributes_to_form_params(obj, staff_roles=nil)
        {
          :"profile_type" => profile_type,
          :"profile_id" => profile_id,
          :"staff_roles" => staff_role_params(staff_roles),
          :"organization" => Serializers::OrganizationSerializer.new(obj).to_hash.merge(
            :"profile" => Serializers::ProfileSerializer.new(pluck_profile(obj)).to_hash
          )
        }
      end

      def form_attributes_to_params(form)
        {
          :"current_user_id" => form.current_user_id,
          :"profile_type" => form.profile_type,
          :"profile_id" => form.profile_id,
          :"staff_roles_attributes" => staff_roles_form_to_params(form.staff_roles),
          :"organization" => organization_form_to_params(form.organization)
        }
      end

      def staff_roles_form_to_params(roles)
        roles.each_with_index.inject({}) do |result, (form, index_val)|
          result[index_val] = form.attributes
          result
        end
      end

      def organization_form_to_params(form)
        organization_attributes(form).merge({
          :profiles_attributes => profiles_form_to_params(form.profile)
        })
      end

      def profiles_form_to_params(profile)
        [profile].each_with_index.inject({}) do |result, (form, index_val)|
          result[index_val] = profile_attributes(form).merge({
            :office_locations_attributes =>  office_locations_form_to_params(form.office_locations)
          })
          result
        end
      end

      def office_locations_form_to_params(locations)
        locations.each_with_index.inject({}) do |result, (form, index_val)|
          result[index_val] = form.attributes.slice(:is_primary, :id).merge({
            :phone_attributes =>  phone_form_to_params(form.phone),
            :address_attributes =>  address_form_to_params(form.address)
          })
          result
        end
      end

      def phone_form_to_params(form)
        form.attributes.slice(:kind, :area_code, :number, :extension, :id)
      end

      def address_form_to_params(form)
        form.attributes.slice(:address_1, :address_2, :city, :kind, :state, :zip, :id)
      end

      def organization_attributes(form)
        form.attributes.slice(:fein, :dba, :legal_name)
      end

      def profile_attributes(form)
        if broker_agency_profile?
          form.attributes.slice(:entity_kind, :contact_method, :id, :market_kind, :home_page, :accept_new_clients, :languages_spoken, :working_hours)
        elsif benefit_sponsor_profile?
          form.attributes.slice(:entity_kind, :contact_method, :id)
        end
      end

      def broker_agency_profile?
        #TODO need to fix this
        false
      end

      def benefit_sponsor_profile?
        true
      end

      def staff_role_params(staff_roles)
        return [{}] if staff_roles.blank?
        [staff_roles].flatten.inject([]) do |result, role|
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

      def save(form)
        persist_from_factory(form)
      end

      def update(form)
        update_from_factory(form)
      end

      def persist_from_factory(form)
        Organizations::Factories::ProfileFactory.call_persist(form_attributes_to_params(form))
      end

      def update_from_factory(form)
        Organizations::Factories::ProfileFactory.call_update(form_attributes_to_params(form))
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

      def pluck_profile(organization)
        if broker_agency_profile?
          organization.profiles.where(_type: /BrokerAgencyProfile/).first
        elsif benefit_sponsor_profile?
          organization.profiles.where(_type: /EmployerProfile/).first
        end
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
