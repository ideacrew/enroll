module BenefitMarkets
  module ContributionModels
    class ContributionModel
      include Mongoid::Document
      include Mongoid::Timestamps

      field :name, type: String

      embeds_many :contribution_units, class_name: "::BenefitMarkets::ContributionModels::ContributionUnit"
      embeds_many :member_relationships, class_name: "::BenefitMarkets::ContributionModels::MemberRelationship"

      validates_presence_of :contribution_units
      validates_presence_of :member_relationships
      validates_presence_of :name, :allow_blank => false
    end
  end
end
