module SponsoredBenefits
  module Organizations
    class AcaShopDcEmployerProfile < Profile

      embeds_one  :general_agency_profile, cascade_callbacks: true, validate: true

      after_initialize :initialize_benefit_sponsorship

      private

      def initialize_benefit_sponsorship
        return unless benefit_sponsorships.blank?
        benefit_sponsorship = benefit_sponsorships.build(site_id: :dc, benefit_market: :aca_shop)
        ## TEMP figure out what we actually want here
        benefit_market = SponsoredBenefits::BenefitMarkets::BenefitMarket.find_by_benefit_sponsorship(:dc, :aca_shop)
        benefit_sponsorship.benefit_market = benefit_market.first
      end
    end
  end
end
