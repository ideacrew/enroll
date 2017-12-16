module SponsoredBenefits
  module BenefitApplications
    class AcaShopCcaBenefitApplicationBuilder < BenefitApplicationBuilder

      def initialize(options={})
        @application_class = AcaShopCcaBenefitApplication
        super(options)
      end

      def add_employer_attestation(new_employer_attestation)
      end

      def add_marketplace_kind(marketplace_kind)
        # raise "marketplace must be aca_shop" unless marketplace_kind == :aca_shop
      end
    end
  end
end
