module BenefitSponsors
  module Organizations
    class BrokerAgencyProfile < BenefitSponsors::Organizations::Profile
      # include SetCurrentUser
      # include AASM
      include ::Config::AcaModelConcern

      MARKET_KINDS = individual_market_is_enabled? ? [:individual, :shop, :both] : [:shop]

      ALL_MARKET_KINDS_OPTIONS = {
        "Individual & Family Marketplace ONLY" => "individual",
        "Small Business Marketplace ONLY" => "shop",
        "Both – Individual & Family AND Small Business Marketplaces" => "both"
      }

      MARKET_KINDS_OPTIONS = ALL_MARKET_KINDS_OPTIONS.select { |k,v| MARKET_KINDS.include? v.to_sym }

      field :market_kind, type: Symbol
      field :corporate_npn, type: String
      field :primary_broker_role_id, type: BSON::ObjectId
      field :default_general_agency_profile_id, type: BSON::ObjectId

      field :languages_spoken, type: Array, default: ["en"] # TODO
      field :working_hours, type: Boolean, default: false
      field :accept_new_clients, type: Boolean

      field :ach_routing_number, type: String
      field :ach_account_number, type: String

      field :aasm_state, type: String

      field :home_page, type: String

      # embeds_many :documents, as: :documentable
      accepts_nested_attributes_for :inbox

      # has_many :broker_agency_contacts, class_name: "Person", inverse_of: :broker_agency_contact
      # accepts_nested_attributes_for :broker_agency_contacts, reject_if: :all_blank, allow_destroy: true

      validates_presence_of :market_kind

      validates :corporate_npn,
        numericality: {only_integer: true},
        length: { minimum: 1, maximum: 10 },
        uniqueness: true,
        allow_blank: true

      validates :market_kind,
        inclusion: { in: Organizations::BrokerAgencyProfile::MARKET_KINDS, message: "%{value} is not a valid practice area" },
        allow_blank: false

      after_initialize :build_nested_models

      scope :active,      ->{ any_in(aasm_state: ["is_applicant", "is_approved"]) }
      scope :inactive,    ->{ any_in(aasm_state: ["is_rejected", "is_suspended", "is_closed"]) }

      # has_one primary_broker_role
      def primary_broker_role=(new_primary_broker_role = nil)
        if new_primary_broker_role.present?
          raise ArgumentError.new("expected BrokerRole class") unless new_primary_broker_role.is_a? BrokerRole
          self.primary_broker_role_id = new_primary_broker_role._id
        else
          unset("primary_broker_role_id")
        end
        @primary_broker_role = new_primary_broker_role
      end

      def primary_broker_role
        return @primary_broker_role if defined? @primary_broker_role
        @primary_broker_role = BrokerRole.find(self.primary_broker_role_id) unless primary_broker_role_id.blank?
      end

      def default_general_agency_profile=(new_default_general_agency_profile = nil)
        if new_default_general_agency_profile.present?
          raise ArgumentError.new("expected GeneralAgencyProfile class") unless new_default_general_agency_profile.is_a? BenefitSponsors::Organizations::GeneralAgencyProfile
          self.default_general_agency_profile_id = new_default_general_agency_profile.id
        else
          unset("default_general_agency_profile_id")
        end
        @default_general_agency_profile = new_default_general_agency_profile
      end

      def default_general_agency_profile
        return @default_general_agency_profile if defined? @default_general_agency_profile
        @default_general_agency_profile = BenefitSponsors::Organizations::GeneralAgencyProfile.find(self.default_general_agency_profile_id) if default_general_agency_profile_id.present?
      end

      private

      def build_nested_models
        build_inbox if inbox.nil?
      end
    end
  end
end
