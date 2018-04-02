module BenefitMarkets
  module ContributionModels
    class MemberRelationship
      include Mongoid::Document

      embedded_in :contribution_model, :inverse_of => :member_relationships

      field :relationship_name, type: Symbol
      field :relationship_kinds, type: Array

      validates_presence_of :relationship_name, :allow_blank => false
      validates_presence_of :relationship_kinds, :allow_blank => false

      def match?(relationship)
        relationship_kinds.any? do |rk|
          rk.to_s == relationship.to_s
        end
      end
    end
  end
end
