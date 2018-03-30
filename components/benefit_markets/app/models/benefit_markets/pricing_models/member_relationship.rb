module BenefitMarkets
  module PricingModels
    class MemberRelationship
      include Mongoid::Document

      embedded_in :pricing_model, :inverse_of => :member_relationships

      field :relationship_name, type: Symbol
      field :relationship_kinds, type: Array

      validates_presence_of :relationship_name, :allow_blank => false
      validates_presence_of :relationship_kinds, :allow_blank => false
    end
  end
end
