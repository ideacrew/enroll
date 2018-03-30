module BenefitMarkets
  class BenefitCatalog
  include Mongoid::Document
  include Mongoid::Timestamps


    has_many :benefit_applications,
             class_name: "::BenefitSponsors::BenefitApplications::BenefitApplication"

    # All ProductPackages that Sponsor is eligible to offer to members
    def product_packages_for(benefit_application)
    end

    def product_packages_by_benefit_kind() # => health, dental
    end

    def issuers_for(benefit_application)
    end

    def benefit_types_for(benefit_application)
    end


  end
end
