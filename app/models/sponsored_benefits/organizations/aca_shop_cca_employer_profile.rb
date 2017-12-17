module SponsoredBenefits
  module Organizations
    class AcaShopCcaEmployerProfile < Profile
      include Mongoid::Document
      include Mongoid::Timestamps

      embedded_in :plan_design_organization, class_name: "SponsoredBenefits::Organizations::PlanDesignOrganization"

      field :sic_code, type: String
      
      embeds_one  :benefit_sponsorship, as: :benefit_sponsorable, class_name: "SponsoredBenefits::BenefitSponsorships::BenefitSponsorship"
      embeds_one  :employer_attestation



    end
  end
end
