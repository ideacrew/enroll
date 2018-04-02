module BenefitMarkets
  module ContributionModels
    class ContributionModel
      include Mongoid::Document
      include Mongoid::Timestamps

      field :name, type: String
      # Indicates the subclass of contribution level to be used under
      # our profiles.  This allows the contribution model to specify what
      # model should constrain the values need to be entered by the employer
      # without an explicit dependency.
      field :contribution_level_kind, type: String

      # Indicates the subclass of contribution calculator to be used
      # under our profiles
      field :contribution_calculator_kind, type: String

      embeds_many :contribution_units, class_name: "::BenefitMarkets::ContributionModels::ContributionUnit"
      embeds_many :member_relationships, class_name: "::BenefitMarkets::ContributionModels::MemberRelationship"

      validates_presence_of :contribution_units
      validates_presence_of :contribution_level_kind, :allow_blank => false
      validates_presence_of :contribution_calculator_kind, :allow_blank => false
      validates_presence_of :member_relationships
      validates_presence_of :name, :allow_blank => false

      def contribution_calculator
        @contribution_calculator ||= contribution_calculator_kind.constantize.new
      end

      # Transform an external relationship into the mapped relationship
      # specified by this contribution model.
      def map_relationship_for(relationship)
        member_relationships.detect { |mr| mr.match?(relationship) }.relationship_name
      end
    end
  end
end
