module BenefitSponsors
  class BenefitSponsorships::BenefitSponsorshipAccount
    include Mongoid::Document
    include Mongoid::Timestamps

    embeds_many :transactions,
          class_name: "::BenefitSponsors::BenefitSponsorships::FinancialTransaction"

  end
end