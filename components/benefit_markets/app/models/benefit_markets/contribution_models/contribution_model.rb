module BenefitMarkets
  module ContributionModels
    class ContributionModel
      include Mongoid::Document
      include Mongoid::Timestamps

      field :name, type: String

      embeds_many :contribution_units, class_name: "::BenefitMarkets::ContributionModels::ContributionUnit"

      validates_presence_of :contribution_units
      validates_presence_of :name, :allow_blank => false
    end
  end
end
