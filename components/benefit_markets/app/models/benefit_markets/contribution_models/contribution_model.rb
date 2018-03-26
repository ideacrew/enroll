module BenefitMarkets
  module ContributionModels
    class ContributionModel
      include Mongoid::Document
      include Mongoid::Timestamps

      field :name, type: String
      # Indicates the subclass of contribution unit value to be used under
      # our profiles.  This allows the contribution model to specify what
      # model should constrain the values need to be entered by the employer
      # without an explicit dependency.
      field :contribution_value_kind, type: String

      embeds_many :contribution_units, class_name: "::BenefitMarkets::ContributionModels::ContributionUnit"
      embeds_many :member_relationships, class_name: "::BenefitMarkets::ContributionModels::MemberRelationship"

      validates_presence_of :contribution_units
      validates_presence_of :contribution_value_kind, :allow_blank => false
      validates_presence_of :member_relationships
      validates_presence_of :name, :allow_blank => false
    end
  end
end
