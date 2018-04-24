module BenefitSponsors
  class Members::SurvivorMember < Members::Member


    after_initialize :set_self_relationship


    private

    def set_self_relationship
      relationship_to_primary_member = :self
    end

  end
end
