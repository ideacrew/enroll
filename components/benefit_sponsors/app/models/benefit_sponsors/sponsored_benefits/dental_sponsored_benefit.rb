module BenefitSponsors
  module SponsoredBenefits
    class DentalSponsoredBenefit < SponsoredBenefit

      field :elected_product_choices, type: Array  # used for choice model to store employer preferences
    end
  end
end
