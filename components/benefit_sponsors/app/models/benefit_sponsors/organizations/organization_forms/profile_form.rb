module BenefitSponsors
  module Organizations
    class OrganizationForms::ProfileForm
      include Virtus.model
      include ActiveModel::Validations

      attribute :id, String
      attribute :entity_kind, Symbol
      attribute :profile_source, String
      attribute :market_kind, Symbol
      attribute :is_benefit_sponsorship_eligible, String
      attribute :corporate_npn, String
      attribute :languages_spoken, String
      attribute :working_hours, Boolean
      attribute :accept_new_clients, Boolean
      attribute :home_page, String
      attribute :contact_method, String
      attribute :entity_kind_options, Array
      attribute :market_kind_options, Hash
      attribute :language_options, Array
      attribute :contact_method_options, Hash
      attribute :profile_type, String
      attribute :sic_code, String
      attribute :inbox, OrganizationForms::InboxForm
      attribute :parent, OrganizationForms::OrganizationForm

      attribute :office_locations, Array[OrganizationForms::OfficeLocationForm]

      validates_presence_of :entity_kind
      validates_presence_of :market_kind, if: :is_broker_profile?

      def persisted?
        false
      end

      def office_locations_attributes=(locations_params)
        self.office_locations=(locations_params.values)
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
