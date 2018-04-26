module BenefitSponsors
  module Organizations
    class Forms::RegistrationForm
      include ActiveModel::Validations
      #extend  ActiveModel::Naming
      #include ActiveModel::Conversion
      include Virtus.model

      attribute :current_user_id, String
      attribute :profile_type, String
      attribute :profile_id, String
      attribute :staff_roles, Array[Forms::StaffRoleForm]
      attribute :organization, Forms::OrganizationForm

      validate :registration_form

      def staff_roles_attributes=(attrs)
        self.staff_roles = attrs.values.inject([]) do |result, role|
          result << Forms::StaffRoleForm.new(role)
          result
        end
      end

      def persisted?
        if profile_id.present?
          return true
        end
        false
      end

      def self.for_new(profile_type)
        service = resolve_service(profile_type)
        form_params = service.build(profile_type)
        new(form_params)
      end

      def self.for_create(attrs)
        new(attrs)
      end

      def self.for_edit(profile_id)
        service = resolve_service(profile_id)
        form_params = service.find
        new(form_params)
      end

      def self.for_update(attrs)
        new(attrs)
      end

      def self.for_broker_portal(user)
        profile_id = Services::NewProfileRegistrationService.for_broker_agency_portal(user)
        if profile_id.present?
          return [true, profile_id]
        else
          return [false, nil]
        end
      end

      def save
        persist!
      end

      def update
        update!
      end

      def persist!
        return false unless valid?
        service({profile_type: profile_type}).store!(self)
      end

      def update!
        return false unless valid?
        service({profile_id: profile_id}).store!(self)
      end

      # TODO : Refactor validating sub-documents.
      def registration_form
        validate_staff_role
        validate_form(self.organization)
        validate_form(self.organization.profile)
        validate_office_locations(self.organization.profile)
      end

      def validate_staff_role
        self.staff_roles.each do |staff_role|
          validate_form(staff_role)
        end
      end

      def validate_office_locations(profile_form)
        profile_form.office_locations.each do |location_form|
          validate_form(location_form)
        end
      end

      def validate_form(form)
        unless form.valid?
          self.errors.add(:base, form.errors.full_messages)
        end
      end

      protected

      def self.resolve_service(attrs ={})
        Services::NewProfileRegistrationService.new(attrs)
      end

      def service(attrs={})
        return @service if defined?(@service)
        @service = self.class.resolve_service(attrs)
      end

      private

      def build(profile_type)
        service.build({profile_type: profile_type})
      end
    end
  end
end
