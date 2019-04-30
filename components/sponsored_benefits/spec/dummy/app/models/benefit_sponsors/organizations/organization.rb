# Organization type with relaxed data entry/validation policies used for government agencies, 
# embassies and other types where FEIN is not assigned/available
module BenefitSponsors
  module Organizations
    class Organization
      include Mongoid::Document

      field :hbx_id, type: String

      field :home_page, type: String

      field :legal_name, type: String
      field :dba, type: String
      field :entity_kind, type: Symbol
      field :fein, type: String

      ENTITY_KINDS =[
        :tax_exempt_organization,
        :c_corporation,
        :s_corporation,
        :partnership,
        :limited_liability_corporation,
        :limited_liability_partnership,
        :household_employer,
      ]

      EXEMPT_ENTITY_KINDS = [
        :governmental_employer,
        :foreign_embassy_or_consulate,
        :health_insurance_exchange,
      ]


      belongs_to  :site, inverse_of: :site_organizations, counter_cache: true,
        class_name: "BenefitSponsors::Site"

      belongs_to  :site_owner, inverse_of: :owner_organization,
                  class_name: "BenefitSponsors::Site"

      embeds_many :profiles,
                  class_name: "BenefitSponsors::Organizations::Profile", cascade_callbacks: true

      def employer_profile
        self.profiles.where(_type: /.*EmployerProfile$/).first
      end

      def broker_agency_profile
        self.profiles.where(_type: /.*BrokerAgencyProfile$/).first
      end
    end
  end
end
