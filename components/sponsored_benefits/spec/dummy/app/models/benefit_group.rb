class BenefitGroup

  include Mongoid::Document
  include Mongoid::Timestamps

  PERSONAL_RELATIONSHIP_KINDS = [
    :employee,
    :spouse,
    :domestic_partner,
    :child_under_26,
    :child_26_and_over
  ].freeze

  field :title, type: String, default: ""
  field :description, type: String, default: ""
  field :reference_plan_id, type: BSON::ObjectId
  field :dental_reference_plan_id, type: BSON::ObjectId

  field :plan_option_kind, type: String
  field :dental_plan_option_kind, type: String
  field :elected_plan_ids, type: Array, default: []
  field :effective_on_kind, type: String, default: "first_of_month"
  field :terminate_on_kind, type: String, default: "end_of_month"
  field :effective_on_offset, type: Integer, default: 0
  field :lowest_cost_plan_id, type: BSON::ObjectId
  field :highest_cost_plan_id, type: BSON::ObjectId

  field :elected_dental_plan_ids, type: Array, default: []
  field :elected_plan_ids, type: Array, default: []

  embeds_many :relationship_benefits, cascade_callbacks: true
  accepts_nested_attributes_for :relationship_benefits, reject_if: :all_blank, allow_destroy: true

  embeds_many :dental_relationship_benefits, cascade_callbacks: true
  accepts_nested_attributes_for :dental_relationship_benefits, reject_if: :all_blank, allow_destroy: true

  embeds_many :composite_tier_contributions, cascade_callbacks: true
  accepts_nested_attributes_for :composite_tier_contributions, reject_if: :all_blank, allow_destroy: true

  validates_presence_of :relationship_benefits, :effective_on_kind, :terminate_on_kind, :effective_on_offset,
                        :reference_plan_id, :plan_option_kind, :elected_plan_ids

  validates_uniqueness_of :title

  def reference_plan=(new_reference_plan)
    raise ArgumentError.new("expected Plan") unless new_reference_plan.is_a? Plan
    self.reference_plan_id = new_reference_plan._id
    @reference_plan = new_reference_plan
  end

  def dental_reference_plan=(new_reference_plan)
    raise ArgumentError.new("expected Plan") unless new_reference_plan.is_a? Plan
    self.dental_reference_plan_id = new_reference_plan._id
    @dental_reference_plan = new_reference_plan
  end

  def reference_plan
    return @reference_plan if defined? @reference_plan
    @reference_plan = Plan.find(reference_plan_id) unless reference_plan_id.nil?
  end

  def dental_reference_plan
    return @dental_reference_plan if defined? @dental_reference_plan
    @dental_reference_plan = Plan.find(dental_reference_plan_id) if dental_reference_plan_id.present?
  end


  def self.find(id)
  end

  def elected_plans_by_option_kind
    case plan_option_kind
    when "sole_source"
      Plan.where(id: reference_plan_id).first
    when "single_plan"
      Plan.where(id: reference_plan_id).first
    when "single_carrier"
      Plan.where(id: reference_plan_id).to_a
    when "metal_level"
      Plan.where(id: reference_plan_id).to_a
    end
  end

  def sole_source?
    plan_option_kind == "sole_source"
  end

  def elected_plans=(new_plans)
    return unless new_plans.present?
    @elected_plans = new_plans
  end

  def elected_dental_plans=(new_plans)
    return unless new_plans.present?
    @elected_dental_plans = new_plans
  end

  def build_relationship_benefits
    relationship_benefits = PERSONAL_RELATIONSHIP_KINDS.map do |relationship|
      self.relationship_benefits.build(relationship: relationship, offered: true)
    end
  end

  def build_composite_tier_contributions
    composite_tier_contributions = CompositeRatingTier::NAMES.map do |rating_tier|
      self.composite_tier_contributions.build(composite_rating_tier: rating_tier, offered: true)
    end
  end

  def build_dental_relationship_benefits
    dental_relationship_benefits = PERSONAL_RELATIONSHIP_KINDS.map do |relationship|
      self.dental_relationship_benefits.build(relationship: relationship, offered: true)
    end
  end

  def set_bounding_cost_plans
    true
    # toDo
    self.lowest_cost_plan_id  = Plan.all[-1]
    self.highest_cost_plan_id = Plan.all[-1]
  end

  def set_bounding_cost_dental_plans
    true
  end

  def elected_dental_plans_by_option_kind
    if dental_plan_option_kind == "single_carrier"
      Plan.by_active_year(start_on.year).shop_market.dental_coverage.by_carrier_profile(carrier_for_elected_dental_plan)
    else
      Plan.by_active_year(start_on.year).shop_market.dental_coverage
    end
  end

  def start_on
    benefit_application.start_on
  end

  def single_plan_type?
    plan_option_kind == "single_plan"
  end

  def sic_factor_for(plan)
    return 1.0
  end

  def group_size_factor_for(plan)
    return 1.0
  end
end
