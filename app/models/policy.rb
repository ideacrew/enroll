class Policy
  include Mongoid::Document
  include Mongoid::Timestamps

  include AASM

  # TODO: Set seed value outside current number series
  # or change ID to embed hbx identifier
  auto_increment :hbx_id, :seed => 999999

  field :effective_on, type: Date
  field :terminated_on, type: Date

  field :plan_id, type: BSON::ObjectId
  field :hbx_carrier_id, type: String

  # Premium amount for which the consumer/employee is responsible
  field :family_premium_in_cents, as: :total_responsible_amount, type: Integer, default: 0

  # Premium amount for which the employer is responsible
  field :er_premium_in_cents, type: Integer, default: 0

  # Total premium amount
  field :premium_total_in_cents, type: Integer, default: 0

  field :sep_reason, type: String, default: :open_enrollment
  field :carrier_to_bill, type: Boolean

  field :updated_by, type: String
  field :aasm_state, type: String
  field :is_active, type: Boolean, default: true

  embeds_many :premium_credits
  accepts_nested_attributes_for :premium_credits, reject_if: :all_blank, allow_destroy: true

  embeds_many :enrollees
  accepts_nested_attributes_for :enrollees, reject_if: :all_blank, allow_destroy: true

  # belongs_to :employer, counter_cache: true, index: true

  # belongs_to :consumer_role
  field :consumer_role_id, type: BSON::ObjectId

  # belongs_to :employee
  # belongs_to :responsible_party
  # belongs_to :plan

  # belongs_to :broker
  # belongs_to :hbx_enrollment

  index({:hbx_id => 1})
  index({:effective_on => 1})
  index({:terminated_on => 1}, {sparse: true})
  index({:aasm_state => 1})
  index({ "enrollees.person_id" => 1 })
  index({ "enrollees.coverage_start_on" => 1 })
  index({ "enrollees.coverage_end_on" => 1}, {sparse: true})

  validates_presence_of :hbx_id, :plan_id, :effective_on, :premium_total_in_cents, :family_premium_in_cents

  scope :all_active_states,   ->{where(:aasm_state.in => %w[applicant submitted transmitted effectuated])}
  scope :all_inactive_states, ->{where(:aasm_state.in => %w[hbx_canceled hbx_terminated carrier_canceled carrier_terminated])}

  def self.find_by_person(person_instance)
    self.where("enrollees.person_id" => person_instance.id).order_by([:hbx_id])
  end

  def set_policy_premium
    enrollees.each do
      price_premium
    end
  end

  def market
    employer_id.present? ? :shop : :individual
  end

  def coverage_type
    self.plan.coverage_type
  end

  # Get amount from current premium_credits instance
  def aptc_in_cents
    return 0 if premium_credits.nil?

    # TODO: determine the current instance & return value
  end

  def family_premium_in_dollars=(new_family_premium)
    family_premium_in_cents = dollars_to_cents(new_family_premium)
  end

  def family_premium_in_dollars
    cents_to_dollars(family_premium_in_cents)
  end

  def er_premium_in_dollars=(new_er_premium)
    er_premium_in_cents = dollars_to_cents(new_er_premium)
  end

  def er_premium_in_dollars
    cents_to_dollars(er_premium_in_cents)
  end

  def premium_total_in_dollars=(new_premium_total)
    premium_total_in_cents = dollars_to_cents(new_premium_total)
  end

  def premium_total_in_dollars
    cents_to_dollars(premium_total_in_cents)
  end

  def aptc_in_dollars
    return 0 if premium_credits.nil?
    cents_to_dollars(aptc_in_cents)

    # TODO determine most recent premium_credit record 
  end

  def plan=(new_plan)
    raise ArgumentError.new("expected Directory::Plan class") unless new_plan.is_a? Directory::Plan
    self.plan_id = new_plan._id

    calculate_enrollee_premiums
  end

  def plan
    Directory::Plan.where(id: self.plan_id).first unless plan_id.nil?
  end

  def calculate_enrollee_premiums

  end

  def canceled?
    hbx_canceled? || carrier_canceled?
  end

  def started_on
    subscriber.coverage_start
  end

  def ended_on
    subscriber.coverage_end
  end

  def carrier_to_bill?
    carrier_to_bill
  end

  def is_active?
    currently_active?
  end

  aasm do
    state :applicant, initial: true
    state :submitted
    state :transmitted
    state :ack
    state :nak
    state :effectuated
    state :carrier_canceled
    state :carrier_terminated
    state :hbx_canceled
    state :hbx_terminated

    event :initial_enrollment do
      transitions from: :applicant, to: :submitted
    end

    event :transmit do
      transitions from: [:submitted, :nak], to: :transmitted
    end

    event :acknowledge do
      transitions from: :transmitted, to: [:ack, :nak]
    end

    event :effectuate do
      transitions from: :ack, to: :effectuated
      transitions from: :effectuated, to: :effectuated
    end

    event :carrier_cancel do
      transitions from: :submitted, to: :carrier_canceled
      transitions from: :carrier_canceled, to: :carrier_canceled
      transitions from: :carrier_terminated, to: :carrier_canceled
      transitions from: :hbx_canceled, to: :hbx_canceled
      transitions from: :hbx_terminated, to: :carrier_canceled
    end

    event :carrier_terminate do
      transitions from: [:submitted, :ack], to: :carrier_terminated
      transitions from: :effectuated, to: :carrier_terminated
      transitions from: :carrier_terminated, to: :carrier_terminated
      transitions from: :hbx_terminated, to: :hbx_terminated
    end

    event :hbx_cancel do
      transitions from: [:submitted, :ack, :nak], to: :hbx_canceled
      transitions from: :effectuated, to: :hbx_canceled
      transitions from: :carrier_canceled, to: :hbx_canceled
      transitions from: :carrier_terminated, to: :hbx_canceled
      transitions from: :hbx_canceled, to: :hbx_canceled
      transitions from: :hbx_terminated, to: :hbx_canceled
    end

    event :hbx_terminate do
      transitions from: :submitted, to: :hbx_terminated
      transitions from: :effectuated, to: :hbx_terminated
      transitions from: :carrier_terminated, to: :carrier_terminated
      transitions from: :carrier_canceled, to: :hbx_terminated
      transitions from: :hbx_terminated, to: :hbx_terminated
    end

    event :hbx_reinstate do
      transitions from: :carrier_terminated, to: :submitted
      transitions from: :carrier_canceled, to: :submitted
      transitions from: :hbx_terminated, to: :submitted
      transitions from: :hbx_canceled, to: :submitted
    end

    # Carrier Attestation documentation reference should accompany this non-standard transition
    event :carrier_reinstate do
      transitions from: [:carrier_terminated, :carrier_canceled], to: :effectuated
    end
  end

private
  def dollars_to_cents(amount_in_dollars)
    Rational(amount_in_dollars) * Rational(100) if amount_in_dollars
  end

  def cents_to_dollars(amount_in_cents)
    (Rational(amount_in_cents) / Rational(100)).to_f if amount_in_cents
  end

  def format_money(val)
    sprintf("%.02f", val)
  end

  def filter_delimiters(str)
    str.to_s.gsub(',','') if str.present?
  end

  def filter_non_numbers(str)
    str.to_s.gsub(/\D/,'') if str.present?
  end

end
