module BenefitSponsors
  module Organizations
    class Forms::Profile
      include ActiveModel::Validations
      include ::Validations::Email
      include BenefitSponsors::Forms::NpnField

      attr_accessor :organization
      attr_accessor :legal_name, :fein, :dba, :entity_kind, :market_kind, :entity_kind, :languages_spoken, :working_hours, 
                      :accept_new_clients, :home_page, :email
      attr_accessor :is_primary
      attr_accessor :address_1, :address_2, :address_3, :county, :country_name, :kind, :city, :state, :zip
      attr_accessor :country_code, :area_code, :number, :extension, :full_phone_number
      attr_accessor :profile_type
      attr_accessor :first_name, :last_name, :dob
      attr_accessor :profiles_attributes, :office_locations_attributes, :address_attributes, :phone_attributes

      validates :fein,
        length: { is: 9, message: "%{value} is not a valid FEIN" },
        numericality: true
      validates_presence_of :dob, :if => Proc.new { |m| m.person_id.blank? }
      validates_presence_of :first_name, :if => Proc.new { |m| m.person_id.blank? }
      validates_presence_of :last_name, :if => Proc.new { |m| m.person_id.blank? }
      validates_presence_of :fein, :legal_name
      validates :entity_kind,
        inclusion: { in: Organizations::Organization::ENTITY_KINDS, message: "%{value} is not a valid business entity kind" },
        allow_blank: false

      # validate :office_location_validations
      # validate :office_location_kinds



      validates :market_kind,
          inclusion: { in: BenefitSponsors::Organizations::BrokerAgencyProfile::MARKET_KINDS, message: "%{value} is not a valid practice area" },
          allow_blank: false, if: :is_broker_profile?

      validates :email, :email => true, :allow_blank => false, if: :is_broker_profile?

      validates_format_of :email, :with => /\A[^@\s]+@([^@\s]+\.)+[^@\s]+\z/, message: "%{value} is not valid", if: :is_broker_profile?

      def initialize(attrs = {})
        @profile_type = attrs[:profile_type]
        assign_wrapper_attributes(attrs)
        build_parent_organization_obj(attrs)
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
        @dob = Date.strptime(val,"%Y-%m-%d") rescue nil
      end
      
      # Strip non-numeric characters
      def fein=(new_fein)
        @fein =  new_fein.to_s.gsub(/\D/, '') rescue nil
      end

      def entity_kind=(entity_kind)
        @entity_kind = entity_kind.to_sym
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
    end
  end
end
