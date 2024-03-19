# frozen_string_literal: true

class BenefitEligibilityElementGroup
  include Mongoid::Document

  embedded_in :benefit_package

  INDIVIDUAL_MARKET_RELATIONSHIP_CATEGORY_KINDS = %w[
      self
      spouse
      domestic_partner
      child
      parent
      sibling
      ward
      guardian
      unrelated
      other_tax_dependent
      aunt_or_uncle
      nephew_or_niece
      grandchild
      grandparent
    ].freeze

  Relationships_UI = %w[
      self
      spouse
      domestic_partner
      child
      parent
      sibling
      unrelated
      aunt_or_uncle
      nephew_or_niece
      grandchild
      grandparent
    ] + (EnrollRegistry.feature_enabled?(:mitc_relationships) ? %w[father_or_mother_in_law daughter_or_son_in_law brother_or_sister_in_law cousin domestic_partners_child parents_domestic_partner] : [])

  SHOP_MARKET_RELATIONSHIP_CATEGORY_KINDS = %w[
      self
      spouse
      domestic_partner
      children_under_26
      disabled_children_26_and_over
      children_26_and_over
    ].freeze


  field :market_places,          type: Array, default: ["any"]
  field :enrollment_periods,     type: Array, default: ["any"]
  field :family_relationships,   type: Array, default: ["any"]
  field :benefit_categories,     type: Array, default: ["any"]

  field :incarceration_status,   type: Array, default: ["any"]
  field :age_range,              type: Range, default: 0..0
  field :citizenship_status,     type: Array, default: ["any"]
  field :residency_status,       type: Array, default: ["any"]
  field :ethnicity,              type: Array, default: ["any"]
  field :cost_sharing,           type: String, default: ""
  field :lawful_presence_status, type: String, default: ""
  field :active_individual_role, type: Boolean, default: false
end
