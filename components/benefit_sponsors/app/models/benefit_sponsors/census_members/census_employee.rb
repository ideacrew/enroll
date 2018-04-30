module BenefitSponsors::CensusMembers
  class CensusEmployee < CensusMember

    has_many :census_survivors, class_name: "BenefitSponsors::CensusMembers::CensusSurvivor"
    embeds_many :census_dependents, as: :census_dependent, class_name: "BenefitSponsors::CensusMembers::CensusDependent"
    
    class << self
      def find_by_benefit_sponsorship(benefit_sponsorship_id)
        #TODO
      end
    end

  end
end
