module SponsoredBenefits
  module Organizations
    class AcaShopCcaEmployerProfile < Profile


      field  :sic_code, type: String

      embeds_one  :employer_attestation

      after_initialize :initialize_benefit_sponsorship

      def rating_area
        ::RatingArea.rating_area_for(plan_design_proposal.plan_design_organization.primary_office_location.address)
      end

    private
      def initialize_benefit_sponsorship
        benefit_sponsorships.build(benefit_market: :aca_shop_cca, enrollment_frequency: :rolling_month) if benefit_sponsorships.blank?
      end


    end
  end
end
