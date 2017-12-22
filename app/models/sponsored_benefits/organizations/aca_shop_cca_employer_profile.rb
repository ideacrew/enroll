module SponsoredBenefits
  module Organizations
    class AcaShopCcaEmployerProfile < Profile

      # embedded_in :plan_design_proposal, class_name: "SponsoredBenefits::Organizations::PlanDesignProposal"

      field  :sic_code, type: String
      embeds_one  :employer_attestation

      after_initialize :initialize_benefit_sponsorship


    private
      def initialize_benefit_sponsorship
      end


    end
  end
end
