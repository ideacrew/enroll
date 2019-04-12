class BenefitGroup

  include Mongoid::Document
  include Mongoid::Timestamps

  PERSONAL_RELATIONSHIP_KINDS = [
    :employee,
    :spouse,
    :domestic_partner,
    :child_under_26,
    :child_26_and_over
  ]

  field :title, type: String, default: ""
  field :terminate_on_kind, type: String, default: "end_of_month"
  field :description, type: String, default: ""
  field :effective_on_offset, type: Integer, default: 0
  field :effective_on_kind, type: String, default: "first_of_month"
  field :reference_plan_id, type: BSON::ObjectId
  field :plan_option_kind, type: String
  field :elected_plan_ids, type: Array, default: []
  field :dental_plan_option_kind, type: String
  field :dental_reference_plan_id, type: BSON::ObjectId

  embeds_many :relationship_benefits, cascade_callbacks: true
  embeds_many :composite_tier_contributions, cascade_callbacks: true
  embeds_many :dental_relationship_benefits, cascade_callbacks: true

  accepts_nested_attributes_for :relationship_benefits, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :dental_relationship_benefits, reject_if: :all_blank, allow_destroy: true

  def self.find(id)
  end

  def build_relationship_benefits
    self.relationship_benefits = PERSONAL_RELATIONSHIP_KINDS.map do |relationship|
       self.relationship_benefits.build(relationship: relationship, offered: true)
    end
  end

  def build_composite_tier_contributions
    self.composite_tier_contributions = CompositeRatingTier::NAMES.map do |rating_tier|
      self.composite_tier_contributions.build(composite_rating_tier: rating_tier, offered: true)
    end
  end

  def build_dental_relationship_benefits
    self.dental_relationship_benefits = PERSONAL_RELATIONSHIP_KINDS.map do |relationship|
       self.dental_relationship_benefits.build(relationship: relationship, offered: true)
    end
  end

  def elected_dental_plans_by_option_kind
  end

  def elected_dental_plans=(new_plans)
  end

  def set_bounding_cost_dental_plans
  end

  def set_bounding_cost_plans
  end

  def sole_source?
    plan_option_kind == "sole_source"
  end

  def elected_plans=(new_plans)
  end

  def elected_plans_by_option_kind
  end

  def elected_plans
  end

end