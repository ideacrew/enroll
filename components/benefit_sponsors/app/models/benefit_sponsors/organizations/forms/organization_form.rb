module BenefitSponsors
  module Organizations
    class Forms::OrganizationForm
      include ActiveModel::Validations
      include ::Validations::Email
      include BenefitSponsors::Forms::NpnField
      extend  ActiveModel::Naming
      include ActiveModel::Conversion
      include Virtus.model

      attribute :fein, String
      attribute :entity_kind, String
      attribute :legal_name, String
      attribute :dba, String

      attribute :profiles, Array[Forms::ProfileForm]
      attribute :profile, Forms::ProfileForm
      attribute :profile_type

      validate :profile_forms

      validates :fein,
        length: { is: 9, message: "%{value} is not a valid FEIN" },
        numericality: true

      validates_presence_of :dob, :if => Proc.new { |m| m.person_id.blank? }
      validates_presence_of :first_name, :if => Proc.new { |m| m.person_id.blank? }
      validates_presence_of :last_name, :if => Proc.new { |m| m.person_id.blank? }
      validates_presence_of :fein, :legal_name

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

      def first_name=(val)
        @first_name = val.blank? ? nil : val.strip
      end

      def last_name=(val)
        @last_name = val.blank? ? nil : val.strip
      end

      def legal_name=(val)
        @legal_name = val.blank? ? nil : val.strip
      end

      def dob=(val)
        @dob = Date.strptime(val,"%m/%d/%Y") rescue nil
      end
      
      # Strip non-numeric characters
      def fein=(new_fein)
        @fein =  new_fein.to_s.gsub(/\D/, '') rescue nil
      end

      def entity_kind=(entity_kind)
        @entity_kind = entity_kind.to_sym
      end

      def market_kind=(market_kind)
        @market_kind = market_kind.to_sym
      end

      def profiles_attributes=(profiles)
        profiles.values.each do |attributes|
          assign_wrapper_attributes(attributes)
        end
      end

      def office_locations_attributes=(locations)
        locations.values.each do |attributes|
          assign_wrapper_attributes(attributes)
        end
      end

      def address_attributes=(attributes)
        assign_wrapper_attributes(attributes)
      end

      def phone_attributes=(attributes)
        assign_wrapper_attributes(attributes)
      end

      def agency_organization=(attributes)
        assign_wrapper_attributes(attributes)
      end

      def office_location_validations # Should be in factory
        @office_locations.each_with_index do |ol, idx|
          ol.valid?
          ol.errors.each do |k, v|
            self.errors.add("office_locations_attributes.#{idx}.#{k}", v)
          end
        end
      end

      def office_location_kinds # Should be in factory
        location_kinds = office_locations.flat_map(&:address).flat_map(&:kind)
        #too_many_of_a_kind = location_kinds.group_by(&:to_s).any? { |k, v| v.length > 1 }

        #if too_many_of_a_kind
        #  self.errors.add(:base, "may not have more than one of the same kind of address")
        #end

        if location_kinds.count('primary').zero?
          self.errors.add(:base, "must select one primary address")
        elsif location_kinds.count('primary') > 1
          self.errors.add(:base, "can't have multiple primary addresses")
        elsif location_kinds.count('mailing') > 1
          self.errors.add(:base, "can't have more than one mailing address")
        end
      end

      def is_broker_profile?
        profile_type == "broker_agency"
      end

      def is_employer_profile?
        profile_type == "benefit_sponsor"
      end

      def profile_forms
        self.profiles.each do |profile_form|
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
