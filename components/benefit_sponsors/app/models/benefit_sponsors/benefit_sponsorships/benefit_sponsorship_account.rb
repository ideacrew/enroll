# frozen_string_literal: true

module BenefitSponsors
  module BenefitSponsorships
    class BenefitSponsorshipAccount
      include Mongoid::Document
      include Mongoid::Timestamps

      embeds_many :transactions, class_name: "::BenefitSponsors::BenefitSponsorships::FinancialTransaction"
    end
  end
end