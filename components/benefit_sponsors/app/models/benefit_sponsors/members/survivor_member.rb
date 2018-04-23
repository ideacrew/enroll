module BenefitSponsors
  class Members::SurvivorMember


    after_initilize :set_self_relationship


    private

    def set_self_relationship
      relationship_to_primary_member = :self
    end

  end
end
