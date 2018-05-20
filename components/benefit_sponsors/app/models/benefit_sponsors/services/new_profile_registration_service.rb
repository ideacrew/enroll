module BenefitSponsors
  module Services
    class NewProfileRegistrationService

      attr_reader :organization, :profile, :representative
      attr_accessor :profile_type, :profile_id, :factory_class

      def initialize(attrs={})
        @profile_id = attrs[:profile_id]
        @factory_class = BenefitSponsors::Organizations::Factories::ProfileFactory
        @profile_type = attrs[:profile_type] || pluck_profile_type(@profile_id)
      end

      def pluck_profile_type(profile_id)
        return nil if profile_id.blank?
        factory_class.get_profile_type(profile_id)
      end

      def build(attrs)
        organization = factory_class.build(attrs)
        attributes_to_form_params(organization)
      end

      def find
        organization = factory_class.build(profile_id: profile_id)
        staff_roles = factory_class.find_representatives(profile_id, profile_type)
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
          :"profile_type" => (form.profile_type || profile_type),
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
          result[index_val] = sanitize_params(profile_attributes(form)).merge({
            :office_locations_attributes =>  office_locations_form_to_params(form.office_locations)
          })
          result
        end
      end

      def office_locations_form_to_params(locations)
        locations.each_with_index.inject({}) do |result, (form, index_val)|
          result[index_val] = sanitize_params(form.attributes.slice(:is_primary, :id)).merge({
            :phone_attributes =>  phone_form_to_params(form.phone),
            :address_attributes =>  address_form_to_params(form.address)
          })
          result
        end
      end

      def phone_form_to_params(form)
        attrs = form.attributes.slice(:kind, :area_code, :number, :extension, :id)
        sanitize_params attrs
      end

      def address_form_to_params(form)
        attrs = form.attributes.slice(:address_1, :address_2, :city, :kind, :state, :zip, :id)
        sanitize_params attrs
      end

      def sanitize_params attrs
        profile_id.blank? ? attrs.except(:id) : attrs
      end

      def organization_attributes(form)
        form.attributes.slice(:fein, :dba, :legal_name)
      end

      def profile_attributes(form)
        if is_broker_profile?
          form.attributes.slice(:entity_kind, :id, :market_kind, :home_page, :accept_new_clients, :languages_spoken, :working_hours)
        elsif is_sponsor_profile?
          if is_cca_sponsor_profile?
            form.attributes.slice(:entity_kind, :contact_method, :id, :sic_code)
          else
            form.attributes.slice(:entity_kind, :contact_method, :id)
          end
        end
      end

      def staff_role_params(staff_roles)
        return [{}] if staff_roles.blank?
        [staff_roles].flatten.inject([]) do |result, role|
          result << Serializers::StaffRoleSerializer.new(role, profile_id:profile_id, profile_type: profile_type).to_hash
          result
        end
      end

      def is_broker_profile?
        profile_type == "broker_agency"
      end

      def is_sponsor_profile?
        profile_type == "benefit_sponsor"
      end

      def is_cca_sponsor_profile?
        is_sponsor_profile? && site_key == :cca
      end

      def is_dc_sponsor_profile?
        is_sponsor_profile? && site_key == :dc
      end

      def site
        return @site if defined? @site
        @site = BenefitSponsors::ApplicationController::current_site
      end

      def site_key
        site.site_key
      end

      def store!(form)
        factory_obj = Organizations::Factories::ProfileFactory.call(form_attributes_to_params(form))
        if factory_obj.errors.present?
          map_errors_for(factory_obj, onto: form)
          return_type = form.profile_id.present? ? [false, factory_obj.redirection_url_on_update] : [false, factory_obj.redirection_url(factory_obj.pending, false)]
          return return_type
        end
        return_type = form.profile_id.present? ? [true, factory_obj.redirection_url_on_update] : [true, factory_obj.redirection_url(factory_obj.pending, true)]
        return return_type
      end

      def map_errors_for(factory_obj, onto:)
        factory_obj.errors.each do |att, err|
          onto.errors.add(map_model_error_attribute(att), err)
        end
      end

      def map_model_error_attribute(model_attribute_name)
        model_attribute_name
      end

      def pluck_profile(organization)
        if is_broker_profile?
          organization.profiles.where(_type: /BrokerAgencyProfile/).first
        elsif is_sponsor_profile?
          organization.profiles.where(_type: /EmployerProfile/).first
        end
      end

      # definitions for pundit policy
      
      def is_benefit_sponsor_already_registered?(user, form)
        if user.person.present? && user.person.has_active_employer_staff_role?
          # this is should be new employer profile id
          form.profile_id = user.person.active_employer_staff_roles.first.employer_profile_id.to_s
          return false
        end
        true
      end

      def is_broker_agency_registered?(user, form)
        if user.present? && (user.has_broker_agency_staff_role? || user.has_broker_role?)
          # this is should be new broker profile id
          form.profile_id = (user.person.broker_agency_staff_roles.first.benefit_sponsors_broker_agency_profile_id || user.person.broker_role.benefit_sponsors_broker_agency_profile_id.to_s)
          return false
        end
        true
      end

      def is_broker_for_employer?(user, form)
        person = user.person
        return false unless person.broker_role || person.broker_agency_staff_roles.present?
        # TODO - check ER selected this broker or not
        true
      end

      def is_general_agency_staff_for_employer?(user, form)
        return false unless user.person.general_agency_staff_roles.present?
        # TODO - check ER has this GA or not
        true
      end

      def has_broker_role_for_profile?(user, form)
        # TODO
        true
      end

      def is_staff_for_agency?(user, form)
        # TODO
        true
      end
    end
  end
end
