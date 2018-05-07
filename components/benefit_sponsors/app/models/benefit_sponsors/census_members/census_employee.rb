module BenefitSponsors::CensusMembers
  class CensusEmployee < CensusMember

    field :hired_on, type: Date
    field :is_business_owner, type: Boolean, default: false

    belongs_to  :benefit_sponsorship,
            class_name: "BenefitSponsors::BenefitSponsorships::BenefitSponsorship"


    has_many :census_survivors, class_name: "BenefitSponsors::CensusMembers::CensusSurvivor"
    embeds_many :census_dependents, as: :census_dependent, class_name: "BenefitSponsors::CensusMembers::CensusDependent"
    
    class << self
      def to_csv
        # TODO
      end
    end
  end
end
