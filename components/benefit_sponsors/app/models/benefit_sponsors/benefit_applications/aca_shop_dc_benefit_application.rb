module BenefitSponsors
  module BenefitApplications
    class AcaShopDcBenefitApplication < BenefitApplication


      has_many :offered_benefit_products, class_name: "BenefitSponsors::BenefitProducts::BenefitProduct"

    end
  end
end
