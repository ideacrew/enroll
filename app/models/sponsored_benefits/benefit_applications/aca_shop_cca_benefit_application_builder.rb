module SponsoredBenefits
  class BenefitApplications::AcaShopCcaBenefitApplicationBuilder < BenefitApplicationBuilder

    def initialize(options={})
      super(options)
    end

    def add_employer_attestation(new_employer_attestation)
    end


    def add_marketplace_kind(marketplace_kind)
      # raise "marketplace must be aca_shop" unless marketplace_kind == :aca_shop
    end

    def benefit_application
      # raise "" if open_enrollment_term.blank?
    end


  end
end
