module SponsoredBenefits
  class BenefitSponsorship
    include Mongoid::Document


    field :benefit_market, type: Symbol
    

    has_many :benefit_applications, class_name: "SponsoredBenefits::BenefitSponsorship::BenefitApplications::BenefitApplication"


  end
end
