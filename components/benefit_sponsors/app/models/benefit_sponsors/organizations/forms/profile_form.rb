module BenefitSponsors
  module Organizations
    class Forms::ProfileForm
      include Virtus.model
      include ActiveModel::Validations

      attribute :entity_kind, Symbol
      attribute :profile_source, String
      attribute :market_kind, String
      attribute :is_benefit_sponsorship_eligible, String
      attribute :corporate_npn, String
      attribute :languages_spoken, String
      attribute :working_hours, String
      attribute :accept_new_clients, Boolean
      attribute :home_page, String
      attribute :contact_method, String

      attribute :office_locations, Array[Forms::OfficeLocationForm]

      # Person related attrs
      # Move this to person form
      attribute :email, String
      attribute :first_name, String
      attribute :last_name, String

      validates_presence_of :entity_kind

      def persisted?
        false
      end

    end
  end
end
