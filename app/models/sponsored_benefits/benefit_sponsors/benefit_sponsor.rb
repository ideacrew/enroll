module SponsoredBenefits
  class BenefitSponsor
    include Mongoid::Document
    include Mongoid::Timestamps

    #has_many :aca_shop_benefit_applications, as: :sponsorable
  end
end
