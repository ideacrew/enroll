module BenefitMarkets
  module ContributionModels
    class ContributionUnit
      include Mongoid::Document
      include Mongoid::Timestamps

      embedded_in :contribution_model, inverse_of: :contribution_units

      field :name, type: String
      field :display_name, type: String
      field :required, type: Boolean, default: false
      field :default_offering, type: Boolean, default: false
      field :order, type: Integer

      embeds_many :member_relationship_maps, class_name: "::BenefitMarkets::ContributionModels::MemberRelationshipMap"

      validates_presence_of :name, :allow_blank => false
      validates_presence_of :display_name, :allow_blank => false
      validates_presence_of :member_relationship_maps, :allow_blank => false
      validates_numericality_of :order, :allow_blank => false

      def assign_contribution_value_defaults(cv)
        cv.offered = default_offering
        cv.contribution_unit = self
      end
    end
  end
end
