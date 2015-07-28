class BenefitGroup
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :plan_year

  PLAN_OPTION_KINDS = %w(single_plan single_carrier metal_level)
  EFFECTIVE_ON_KINDS = %w(date_of_hire first_of_month)
  OFFSET_KINDS = [0, 30, 60]
  TERMINATE_ON_KINDS = %w(end_of_month)
  PERSONAL_RELATIONSHIP_KINDS = [
    :employee,
    :spouse,
    :domestic_partner,
    :child_under_26,
    :child_26_and_over
  ]

  field :title, type: String, default: ""

  embeds_many :relationship_benefits, cascade_callbacks: true
  accepts_nested_attributes_for :relationship_benefits, reject_if: :all_blank, allow_destroy: true

  field :effective_on_kind, type: String, default: "date_of_hire"
  field :terminate_on_kind, type: String, default: "end_of_month"
  field :plan_option_kind, type: String

  # Number of days following date of hire
  field :effective_on_offset, type: Integer, default: 0

  # Non-congressional
  # belongs_to :reference_plan, class_name: "Plan"
  field :reference_plan_id, type: BSON::ObjectId

  # Employer contribution amount as percentage of reference plan premium
  field :employer_max_amt_in_cents, type: Integer, default: 0

  # Array of plan_ids
  field :elected_plan_ids, type: Array, default: []

  delegate :start_on, :end_on, to: :plan_year

  attr_accessor :metal_level_for_elected_plan, :carrier_for_elected_plan

  #TODO add following attributes: :title,
  validates_presence_of :relationship_benefits, :effective_on_kind, :terminate_on_kind, :effective_on_offset,
                        :reference_plan_id, :plan_option_kind, :elected_plan_ids

  validates_uniqueness_of :title

  validates :plan_option_kind,
    allow_blank: false,
    inclusion: {
      in: PLAN_OPTION_KINDS,
      message: "%{value} is not a valid plan option kind"
    }

  validates :effective_on_kind,
    allow_blank: false,
    inclusion: {
      in: EFFECTIVE_ON_KINDS,
      message: "%{value} is not a valid effective date kind"
    }

  validates :effective_on_offset,
    allow_blank: false,
    inclusion: {
      in: OFFSET_KINDS,
      message: "%{value} is not a valid effective date offset kind"
    }

  validate :plan_integrity
  validate :check_employer_contribution_for_employee
  validate :check_offered_for_employee

  def plan_option_kind=(new_plan_option_kind)
    super new_plan_option_kind.to_s
  end

  def reference_plan=(new_reference_plan)
    raise ArgumentError.new("expected Plan") unless new_reference_plan.is_a? Plan
    self.reference_plan_id = new_reference_plan._id
    @reference_plan = new_reference_plan
  end

  def reference_plan
    return @reference_plan if defined? @reference_plan
    @reference_plan = Plan.find(reference_plan_id) unless reference_plan_id.nil?
  end

  def elected_plans
    return @elected_plans if defined? @elected_plans
    @elected_plans ||= Plan.where(:id => {"$in" => elected_plan_ids}).to_a
  end

  def elected_plans=(new_plans)
    if new_plans.is_a? Array
      self.elected_plan_ids = new_plans.reduce([]) { |list, plan| list << plan._id }
    else
      self.elected_plan_ids = Array.new(1, new_plans.try(:_id))
    end
    @elected_plans = new_plans
  end

  def benefit_group_assignments
    BenefitGroupAssignment.by_benefit_group_id(id)
  end

  def census_employees
    CensusEmployee.find_all_by_benefit_group(self)
  end

  def assignable_to?(census_employee)
    return !(census_employee.employment_terminated_on < start_on || census_employee.hired_on > end_on)
  end

  def effective_on_for(date_of_hire)
    case effective_on_kind
    when "date_of_hire"
      date_of_hire_effective_on_for(date_of_hire)
    when "first_of_month"
      first_of_month_effective_on_for(date_of_hire)
    end
  end

  def employer_max_amt_in_cents=(new_employer_max_amt_in_cents)
    write_attribute(:employer_max_amt_in_cents, dollars_to_cents(new_employer_max_amt_in_cents))
  end

  def premium_in_dollars
    cents_to_dollars(employer_max_amt_in_cents)
  end

  def relationship_benefit_for(relationship)
    relationship_benefits.where(relationship: relationship).first
  end

  def simple_benefit_list(employee_premium_pct, dependent_premium_pct, employer_max_amount)
    [
      RelationshipBenefit.new(benefit_group: self,
                              relationship: :employee,
                              premium_pct: employee_premium_pct,
                              employer_max_amt: employer_max_amount,
                              offered: true),
    ] + PERSONAL_RELATIONSHIP_KINDS.dup.delete_if{|kind| [:employee, :child_26_and_over].include?(kind)}.collect do |relationship|
      RelationshipBenefit.new(benefit_group: self,
                              relationship: relationship,
                              premium_pct: dependent_premium_pct,
                              employer_max_amt: employer_max_amount,
                              offered: true)
    end + [
      RelationshipBenefit.new(benefit_group: self,
                              relationship: :child_26_and_over,
                              premium_pct: employee_premium_pct,
                              employer_max_amt: employer_max_amount,
                              offered: false),
    ]
  end

  def self.find(id)
    orgs = Organization.where({
      "employer_profile.plan_years.benefit_groups._id" => id
    })
    found_value = catch(:found_benefit_group) do
      orgs.each do |org|
        org.employer_profile.plan_years.each do |py|
          py.benefit_groups.each do |bg|
            if bg.id == id
              throw :found_benefit_group, bg
            end
          end
        end
      end
      raise Mongoid::Errors::DocumentNotFound.new(self, id)
    end
    return found_value
  end

  def estimated_monthly_employer_contribution
    plan_year.employer_profile.census_employees.active.collect do |ce|
      pcd = PlanCostDecorator.new(reference_plan, ce, self, reference_plan)
      pcd.total_employer_contribution
    end.sum
  end

  def estimated_monthly_min_employee_cost
    plan_year.employer_profile.census_employees.active.collect do |ce|
      pcd = PlanCostDecorator.new(reference_plan, ce, self, reference_plan)
      pcd.total_employee_cost
    end.min
  end

  def estimated_monthly_max_employee_cost
    plan_year.employer_profile.census_employees.active.collect do |ce|
      pcd = PlanCostDecorator.new(reference_plan, ce, self, reference_plan)
      pcd.total_employee_cost
    end.max
  end

private
  def dollars_to_cents(amount_in_dollars)
    Rational(amount_in_dollars) * Rational(100) if amount_in_dollars
  end

  def cents_to_dollars(amount_in_cents)
    (Rational(amount_in_cents) / Rational(100)).to_f if amount_in_cents
  end

  def date_of_hire_effective_on_for(date_of_hire)
    [plan_year.start_on, date_of_hire].max
  end

  def first_of_month_effective_on_for(date_of_hire)
    [plan_year.start_on, (date_of_hire + effective_on_offset.days).beginning_of_month.next_month].max
  end

  # Non-congressional
  # pick reference plan
  # two pctages
  # toward employee
  # toward each dependent type

  # member level premium in reference plan, apply pctage by type, calc $$ amount.
  # may be applied toward and other offered plan
  # never pay more than premium per person
  # extra may not be applied toward other members

  def plan_integrity
    return if elected_plan_ids.blank?

    if (plan_option_kind == "single_plan") && (elected_plan_ids.first != reference_plan_id)
      self.errors.add(:elected_plans, "single plan must be the reference plan")
    end

    if (plan_option_kind == "single_carrier")
      if !(elected_plan_ids.include? reference_plan_id)
        self.errors.add(:elected_plans, "single carrier must include reference plan")
      end
      if elected_plans.detect { |plan| plan.carrier_profile_id != reference_plan.try(:carrier_profile_id) }
        self.errors.add(:elected_plans, "not all from the same carrier as reference plan")
      end
    end

    if (plan_option_kind == "metal_level") && !(elected_plan_ids.include? reference_plan_id)
      self.errors.add(:elected_plans, "not all of the same metal level as reference plan")
    end
  end

  def check_employer_contribution_for_employee
    start_on = self.plan_year.try(:start_on)
    return if start_on.try(:at_beginning_of_year) == start_on

    if relationship_benefits.present? and (relationship_benefits.find_by(relationship: "employee").try(:premium_pct) || 0) < HbxProfile::ShopEmployerContributionPercentMinimum
      self.errors.add(:relationship_benefits, "Employer contribution must be ≥ 50% for employee")
    end
  end

  def check_offered_for_employee
    if relationship_benefits.present? and (relationship_benefits.find_by(relationship: "employee").try(:offered) != true)
      self.errors.add(:relationship_benefits, "employee must be offered")
    end
  end
end
