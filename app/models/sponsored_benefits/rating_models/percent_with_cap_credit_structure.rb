module SponsoredBenefits
  module RatingModels
    class PercentWithCapCreditStructure < CreditStructure
      include Mongoid::Document
      include Mongoid::Timestamps

      field :contribution_percent_minimum,    type: Integer
      field :contribution_cap_amount,         type: Money

      validate :contribution_percent_minimum,
                numericality: {only_integer: true, inclusion: 0..100},
                allow_nil: false

    end
  end
end
