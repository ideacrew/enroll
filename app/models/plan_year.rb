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

  embeds_one :employer_census
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
end
