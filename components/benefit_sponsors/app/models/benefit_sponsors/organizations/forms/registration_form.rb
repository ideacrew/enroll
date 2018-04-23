module BenefitSponsors
  module Organizations
    class Forms::RegistrationForm
      include ActiveModel::Validations
      #extend  ActiveModel::Naming
      #include ActiveModel::Conversion
      include Virtus.model

      attribute :profile_type, String
      attribute :profile_id, String
      attribute :staff_roles, Array[Forms::StaffRoleForm]
      attribute :organization, Forms::OrganizationForm

      validate :registration_form


      # set profile when id present
      def organization=(val)
        result = super val
        if profile_id.present?
          result.profile = result.profiles.detect {|profile| profile.id == profile_id}
        end
        result
      end

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

      def save(attrs, current_user=nil)
        persist!(attrs, current_user)
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
        form_params = service.find(profile_id)
        new(form_params)
      end

      def self.for_update(attrs)
      end

      def persist!(attrs, current_user)
        return false unless valid?
        service.save(attrs, current_user)
      end

      def update(attrs)
        return false unless valid?
        service.update(attrs)
      end

      def is_broker_profile?
        profile_type == "broker_agency"
      end

      def is_employer_profile?
        profile_type == "benefit_sponsor"
      end

      # TODO : Refactor validating sub-documents.
      def registration_form
        self.staff_roles.each do |staff_role|
          validate_form(staff_role)
        end
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

      protected

      def self.resolve_service(attrs ={})
        Services::NewProfileRegistrationService.new(attrs)
      end

      def service
        return @service if defined?(@service)
        @service = self.class.resolve_service
      end

      private

      def build(profile_type)
        service.build({profile_type: profile_type})
      end
    end
  end
end
