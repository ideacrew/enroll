module BenefitSponsors
  module Organizations
    class Forms::ProfileForm
      include Virtus.model
      include ActiveModel::Validations

      attribute :id, String
      attribute :entity_kind, Symbol
      attribute :profile_source, String
      attribute :market_kind, Symbol
      attribute :is_benefit_sponsorship_eligible, String
      attribute :corporate_npn, String
      attribute :languages_spoken, String
      attribute :working_hours, String
      attribute :accept_new_clients, Boolean
      attribute :home_page, String
      attribute :contact_method, String
      attribute :entity_kind_options, Array
      attribute :contact_method_options, Array
      attribute :profile_type, String

      attribute :office_locations, Array[Forms::OfficeLocationForm]

      validates_presence_of :entity_kind

      def persisted?
        false
      end

      def office_locations_attributes=(locations_params)
        self.office_locations=(locations_params.values)
      end
    end
  end
end
