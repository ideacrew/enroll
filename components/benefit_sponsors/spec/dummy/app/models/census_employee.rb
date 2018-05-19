class CensusEmployee
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :benefit_sponsorship, class_name: "BenefitSponsors::BenefitSponsorships::BenefitSponsorship"
end