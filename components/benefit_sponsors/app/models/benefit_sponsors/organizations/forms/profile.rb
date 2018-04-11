module BenefitSponsors
  module Organizations
    class Forms::Profile
      include ActiveModel::Validations
      include ::Validations::Email
      include BenefitSponsors::Forms::NpnField
      include BenefitSponsors::Forms::ProfileInformation

      attr_accessor :market_kind, :entity_kind, :languages_spoken, :working_hours, 
                      :accept_new_clients, :home_page, :email, :area_code, :number, :extension, :contact_method

      attr_accessor :id, :person_id, :dba, :npn, :office_locations, :profile
      attr_reader :dob, :profile_type, :first_name, :last_name, :fein, :legal_name

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

      validate :office_location_validations
      validate :office_location_kinds



      validates :market_kind,
          inclusion: { in: BenefitSponsors::Organizations::BrokerAgencyProfile::MARKET_KINDS, message: "%{value} is not a valid practice area" },
          allow_blank: false, if: :is_broker_profile?

      validates :email, :email => true, :allow_blank => false, if: :is_broker_profile?

      validates_format_of :email, :with => /\A[^@\s]+@([^@\s]+\.)+[^@\s]+\z/, message: "%{value} is not valid", if: :is_broker_profile?

      def initialize(attrs = {})
        @profile_type = attrs[:profile_type]
        @office_locations ||= []
        assign_wrapper_attributes(attrs.except(:profile_type))
        ensure_office_locations
      end

      def assign_wrapper_attributes(attrs = {})
        attrs.each_pair do |k,v|
          v = v.to_sym if k == 'entity_kind'
          self.send("#{k}=", v)
        end
      end

      def ensure_office_locations
        if @office_locations.empty?
          new_office_location = Locations::OfficeLocation.new
          new_office_location.build_address
          new_office_location.build_phone
          @office_locations = [new_office_location]
        end
      end

      def office_location_validations
        @office_locations.each_with_index do |ol, idx|
          ol.valid?
          ol.errors.each do |k, v|
            self.errors.add("office_locations_attributes.#{idx}.#{k}", v)
          end
        end
      end

      def office_location_kinds
        location_kinds = office_locations.flat_map(&:address).flat_map(&:kind)

        if location_kinds.count('primary').zero?
          self.errors.add(:base, "must select one primary address")
        elsif location_kinds.count('primary') > 1
          self.errors.add(:base, "can't have multiple primary addresses")
        elsif location_kinds.count('mailing') > 1
          self.errors.add(:base, "can't have more than one mailing address")
        end
      end

      def office_locations_attributes
        @office_locations.map do |office_location|
          office_location.attributes
        end
      end

      def save(current_user, attrs)
        return false unless valid?
        Factories::ProfileFactory.call(current_user, attrs)
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
