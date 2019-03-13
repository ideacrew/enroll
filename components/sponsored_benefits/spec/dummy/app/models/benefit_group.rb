class BenefitGroup

  include Mongoid::Document
  include Mongoid::Timestamps

    embedded_in :plan_year

  attr_accessor :metal_level_for_elected_plan, :carrier_for_elected_plan

  PLAN_OPTION_KINDS = %w(single_plan single_carrier metal_level)
  EFFECTIVE_ON_KINDS = %w(date_of_hire first_of_month)
  OFFSET_KINDS = [0, 1, 30, 60]
  TERMINATE_ON_KINDS = %w(end_of_month)
  PERSONAL_RELATIONSHIP_KINDS = [
    :employee,
    :spouse,
    :domestic_partner,
    :child_under_26,
    :child_26_and_over
  ]

  field :title, type: String, default: ""
  field :description, type: String, default: ""
  field :effective_on_kind, type: String, default: "first_of_month"
  field :terminate_on_kind, type: String, default: "end_of_month"
  field :dental_plan_option_kind, type: String
  field :plan_option_kind, type: String
  field :default, type: Boolean, default: false

  field :contribution_pct_as_int, type: Integer, default: 0
  field :employee_max_amt, default: 0
  field :first_dependent_max_amt, default: 0
  field :over_one_dependents_max_amt, default: 0

  # Number of days following date of hire
  field :effective_on_offset, type: Integer, default: 0

  # Non-congressional
  # belongs_to :reference_plan, class_name: "Plan"
  field :reference_plan_id, type: BSON::ObjectId
  field :lowest_cost_plan_id, type: BSON::ObjectId
  field :highest_cost_plan_id, type: BSON::ObjectId

  # Employer contribution amount as percentage of reference plan premium
  field :employer_max_amt_in_cents, type: Integer, default: 0

  # Employer dental plan_ids
  field :dental_relationship_benefits_attributes_time, type: BSON::ObjectId, default: 0
  field :dental_reference_plan_id, type: BSON::ObjectId
  field :elected_dental_plan_ids, type: Array, default: []

  # Array of plan_ids
  field :elected_plan_ids, type: Array, default: []
  field :is_congress, type: Boolean, default: false
  field :_type, type: String, default: self.name

  field :is_active, type: Boolean, default: true

  default_scope ->{ where(is_active: true) }

  delegate :start_on, :end_on, to: :plan_year
  # accepts_nested_attributes_for :plan_year

  delegate :employer_profile, to: :plan_year, allow_nil: true

  embeds_many :relationship_benefits, cascade_callbacks: true
  accepts_nested_attributes_for :relationship_benefits, reject_if: :all_blank, allow_destroy: true

  embeds_many :dental_relationship_benefits, cascade_callbacks: true
  accepts_nested_attributes_for :dental_relationship_benefits, reject_if: :all_blank, allow_destroy: true

  field :carrier_for_elected_dental_plan, type: BSON::ObjectId

  def self.find(id)
    ::Caches::RequestScopedCache.lookup(:employer_calculation_cache_for_benefit_groups, id) do
      if organization = Organization.unscoped.where({"employer_profile.plan_years.benefit_groups._id" => id }).first
        plan_year = organization.employer_profile.plan_years.where({"benefit_groups._id" => id }).first
        plan_year.benefit_groups.unscoped.detect{|bg| bg.id == id }
      else
        nil
      end
    end
  end

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

  def elected_plans=(new_plans)
    return unless new_plans.present?

    if new_plans.is_a? Array
      self.elected_plan_ids = new_plans.reduce([]) { |list, plan| list << plan._id }
    else
      self.elected_plan_ids = Array.new(1, new_plans.try(:_id))
    end

    # set_bounding_cost_plans # toDO
    @elected_plans = new_plans
  end

  def elected_dental_plans=(new_plans)
    return unless new_plans.present?
    self.elected_dental_plan_ids = new_plans.reduce([]) { |list, plan| list << plan._id }

    # set_bounding_cost_plans
    @elected_dental_plans = new_plans
  end

  def elected_plans
    return @elected_plans if defined? @elected_plans
    @elected_plans ||= Plan.where(:id => {"$in" => elected_plan_ids}).to_a
  end

  def elected_dental_plans
    return @elected_dental_plans if defined? @elected_dental_plans
    @elected_dental_plans ||= Plan.where(:id => {"$in" => elected_dental_plan_ids}).to_a
  end
end
