module SponsoredBenefits
  class BenefitApplications::AcaShopCcaBenefitApplicationBuilder < BenefitApplicationBuilder

    def initialize(benefit_sponsor)

      @benefit_application = SponsoredBenefits::BenefitApplications::AcaShopCcaBenefitApplication.new
      @benefit_sponsor = 
      @benefit_market = 

      Settings.site.benefit_market

      super(options)
    end

    def benefit_market
    end


    def add_employer_attestation(new_employer_attestation)
    end


    def add_marketplace_kind(marketplace_kind)
      # raise "marketplace must be aca_shop" unless marketplace_kind == :aca_shop
    end

    def benefit_application
      # raise "" if open_enrollment_term.blank?
    end

    def reset
      @benefit_application = SponsoredBenefits::BenefitApplications::AcaShopCcaBenefitApplication.new
    end

  end
end
