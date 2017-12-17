module SponsoredBenefits
  class BenefitSponsorships::BenefitSponsorship
    include Mongoid::Document

    embeds_many :benefit_applications
  end
end
