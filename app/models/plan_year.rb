class PlanYear
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :employer

  # include MergingModel

  NEW_HIRE_EFFECTIVE_DATE_KIND = %W[
      date_of_hire 
      first_of_month_following_date_of_hire 
      first_of_month_following_30_days
      first_of_month_following_60_days
    ]

  COVERAGE_TERMINATION_DATE_KIND = %W[
      last_day_of_month_following_termination
    ]

  # Plan Year period
  field :start_date, type: Date
  field :end_date, type: Date

  field :open_enrollment_start_date, type: Date
  field :open_enrollment_end_date, type: Date

  # Number of full-time employees
  field :fte_count, type: Integer, default: 0

  # Number of part-time employess
  field :pte_count, type: Integer, default: 0

  # Number of Medicare second payers
  field :msp_count, type: Integer, default: 0

  field :offers_dependent_coverage, type: Boolean

  # has_one association
  field :broker_id, type: BSON::ObjectId
  field :broker_id_as_string, type: String


  embeds_one :employer_roster
  embeds_many :elected_plans

  # has_one :contribution_strategy, :class_name => "EmployerContributions::Strategy", :inverse_of => :plan_year

  def broker=(new_broker)
    return if new_broker.blank?
    self.broker_id = new_broker._id
    self.broker_id_as_string = new_broker._id.to_s
  end

  def broker
    Broker.find(self.broker_id) unless self.broker_id.blank?
  end

  def has_broker?
    !broker_id.blank?
  end

  def offers_dependent_coverage?
    offers_dependent_coverage
  end

  def self.make(data)
    plan_year = PlanYear.new
    plan_year.open_enrollment_start = data[:open_enrollment_start]
    plan_year.open_enrollment_end = data[:open_enrollment_end]
    plan_year.start_date = Date.parse(data[:start_date])
    plan_year.end_date = Date.parse(data[:end_date]) unless data[:end_date].blank?
    plan_year.broker = Broker.find_by_npn(data[:broker_npn])
    plan_year.fte_count = data[:fte_count]
    plan_year.pte_count = data[:pte_count]
    e_plans = []

    data[:plans].each do |plan_data|
      plan = Plan.find_by_hios_id_and_year(plan_data[:qhp_id], plan_year.start_date.year)
      raise plan_data[:qhp_id].inspect if plan.nil?
      e_plans << ElectedPlan.new(
        :carrier_id => plan.carrier_id,
        :qhp_id => plan_data[:qhp_id],
        :coverage_type => plan_data[:coverage_type],
        :metal_level => plan.metal_level,
        :hbx_plan_id => plan.hbx_plan_id,
        :original_effective_date => plan_data[:original_effective_date],
        :plan_name => plan.name,
        :carrier_policy_number => plan_data[:policy_number],
        :carrier_employer_group_id => plan_data[:group_id]
      )
    end
    plan_year.elected_plans.concat(e_plans)
    plan_year
  end

  def update_group_ids(carrier_id, g_id)
    plans_to_update = self.elected_plans.select do |ep|
      ep.carrier_id == carrier_id
    end
    plans_to_update.each do |ep|
      ep.carrier_employer_group_id = g_id
      ep.touch
      ep.save!
    end
  end

  def match(other)
    return false if other.nil?
    attrs_to_match = [:start_date, :end_date]
    attrs_to_match.all? { |attr| attribute_matches?(attr, other) }
  end

  def attribute_matches?(attribute, other)
    self[attribute] == other[attribute]
  end
end
