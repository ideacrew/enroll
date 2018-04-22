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
      # attribute :entity_kind, String
      attribute :legal_name, String
      attribute :dba, String

      attribute :profiles, Array[Forms::ProfileForm] #Look into handling multiple Profiles.
      attribute :profile, Forms::ProfileForm
      # attribute :profile_type, String


      validates :fein,
        length: { is: 9, message: "%{value} is not a valid FEIN" },
        numericality: true

      validates_presence_of :fein, :legal_name

      def persisted?
        false
      end

      def legal_name=(val)
        legal_name = val.blank? ? nil : val.strip
        super legal_name
      end
      
      # Strip non-numeric characters
      def fein=(new_fein)
        fein =  new_fein.to_s.gsub(/\D/, '') rescue nil
        super fein
      end

      def profile=(val)
        profile = val
        super profile
      end

      def profiles_attributes=(profiles_params)
        self.profiles=(profiles_params.values)
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
    end
  end
end
