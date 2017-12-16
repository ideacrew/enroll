module SponsoredBenefits
  class BenefitProducts::BenefitProduct
    include Mongoid::Document
    include Mongoid::Timestamps

    field :benefit_coverage_period, type: Range

    belongs_to :issuer_profile

  end
end
