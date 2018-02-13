module SponsoredBenefits
  module Organizations
    class AcaShopDcEmployerProfile < Profile

      embeds_one  :general_agency_profile, cascade_callbacks: true, validate: true

      after_initialize :initialize_benefit_sponsorship

      private

      def initialize_benefit_sponsorship
        return unless benefit_sponsorship.blank?
        benefit_sponsorship = build_benefit_sponsorship(site_id: :dc, benefit_market: :aca_shop) 
        benefit_market = SponsoredBenefits::BenefitMarkets::BenefitMarket.find_by_benefit_sponsorship(benefit_sponsorship)
        benefit_sponsorship.benefit_market = benefit_market
      end
    end
  end
end
