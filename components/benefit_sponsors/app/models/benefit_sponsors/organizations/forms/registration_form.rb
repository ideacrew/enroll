module BenefitSponsors
  module Organizations
    class Forms::RegistrationForm
      include ActiveModel::Validations
      #extend  ActiveModel::Naming
      #include ActiveModel::Conversion
      include Virtus.model

      # TODO - remove person_form, person serializer, registration serializer

      attribute :staff_role, Forms::StaffRoleForm
      attribute :organization, Forms::OrganizationForm

      validate :registration_form

      def persisted?
        false
      end

      def save
        if valid?
          persist!
          true
        else
          false
        end
      end

      def self.for_new(profile_type)
        service_obj = Services::NewProfileRegistrationService.new
        form_params = service_obj.build(profile_type: profile_type)
        new(form_params)
      end

      def self.for_create(attrs)
      end

      def self.for_edit(profile_id)
      end

      def self.for_update(profile_id, attrs)
      end

      def build_parent_organization_obj(attributes)
        @organization = Factories::ProfileFactory.initialize_parent(attributes)
      end

      def assign_wrapper_attributes(attributes)
        attributes.each_pair do |k, v|
          next unless self.class.method_defined?("#{k}")
          self.send("#{k}=", v)
        end
      end

      def persist(current_user, attrs)
        return false unless valid?
        Factories::ProfileFactory.call_persist(current_user, attrs)
      end

      def update(attrs)
        return false unless valid?
        Factories::ProfileFactory.call_update(organization, attrs.merge({id: organization.id}))
      end

     

      def is_broker_profile?
        profile_type == "broker_agency"
      end

      def is_employer_profile?
        profile_type == "benefit_sponsor"
      end

      # TODO : Refactor validating sub-documents.
      def registration_form
        validate_form(self.person)
        validate_form(self.organization)
        self.organization.profiles.each do |profile_form|
          validate_office_locations(profile_form)
          validate_form(profile_form)
        end
      end

      def validate_office_locations(profile_form)
        profile_form.office_locations.each do |location_form|
          validate_form(location_form)
        end
      end

      def validate_form(form)
        unless form.valid?
          form.errors.add(:base, form.errors.full_messages)
        end
      end

      private

      def build(profile_type)
        BenefitSponsors::Services::NewProfileRegistrationService.build({profile_type: profile_type})
      end
    end
  end
end
