module BenefitMarkets
  module PricingModels
    class PricingModel
      include Mongoid::Document
      include Mongoid::Timestamps

      field :name, type: String
      # Indicates the subclass of contribution unit value to be used under
      # our profiles.  This allows the contribution model to specify what
      # model should constrain the values need to be entered by the employer
      # without an explicit dependency.
      field :price_calculator_kind, type: String

      embeds_many :member_relationships, class_name: "::BenefitMarkets::PricingModels::MemberRelationship"
      embeds_many :pricing_units, class_name: "::BenefitMarkets::PricingModels::PricingUnit"

      validates_presence_of :pricing_units
      validates_presence_of :member_relationships
      validates_presence_of :price_calculator_kind, :allow_blank => false
      validates_presence_of :name, :allow_blank => false

      def pricing_calculator
        @pricing_calculator ||= price_calculator_kind.constantize.new
      end

      # Transform an external relationship into the mapped relationship
      # specified by this pricing model.
      def map_relationship_for(relationship)
        member_relationships.detect { |mr| mr.match?(relationship) }.relationship_name
      end
    end
  end
end
