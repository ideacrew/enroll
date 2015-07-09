class EmployerProfileAccount
  include Mongoid::Document
  include Mongoid::Timestamps
  include AASM

  embedded_in :employer_profile

  field :next_premium_due_on, type: Date
  field :next_premium_amount, type: Money
  field :aasm_state, type: String, default: "binder_pending"

  embeds_many :premium_payments
  embeds_many :workflow_state_transitions, as: :transitional

  accepts_nested_attributes_for :premium_payments

  validates_presence_of :next_premium_due_on, :next_premium_amount

  scope :active,      ->{ not_in(aasm_state: %w(canceled terminated)) }


  def last_premium_payment
    return premium_payments.first if premium_payments.size == 1
    premium_payments.order_by(:paid_on.desc).limit(1).first
  end


  ## TODO -- reconcile the need for history via embeds_many with the state machine functionality
  aasm do
    # Initial open enrollment period closed, first premium payment not received/processed
    state :binder_pending, initial: true
    state :binder_paid, :after_enter => :enroll_employer

    # Enrolled and premium payment up-to-date
    state :current
    state :invoiced
    state :past_due                                          # Premium payment 1-29 days past due
    state :delinquent,  :after_enter => :late_notifications  # Premium payment 30-60 days past due - send notices to employees
    state :suspended,   :after_enter => :suspend_benefit     # Premium payment 61-90 - transmit terms to carriers with retro date   

    state :canceled,    :after_enter => :cancel_benefit      # Coverage never took effect, either voluntarily withdrawal or not paying binder
    state :terminated,  :after_enter => :terminate_benefit   # Premium payment > 90 days past due (day 91) or Employer voluntarily terminates

    # 
    event :allocate_binder_payment, :after => :record_transition do
      transitions from: :binder_pending, to: :binder_paid
    end

    # TODO Advance billing period on binder_pending in middle of month
    event :advance_billing_period, :guard => :first_day_of_month?, :after => :record_transition do
      transitions from: :binder_pending, to: :canceled

      transitions from: :binder_paid, to: :invoiced
      transitions from: :invoiced, to: :past_due
      transitions from: :past_due, to: :delinquent
      transitions from: :delinquent, to: :suspended
      transitions from: :suspended, to: :terminated
      # april 10th open enrollment ends => binder pending
      # april 15th binder is due, paid (allocate binder payment happened) => binder paid, not paid => binder pending
      # may 1st plan year start, binder paid => invoiced (due may 31st), binder pending => canceled
      # may 20th paid bill due 31st, invoiced => current
      # june 1st haven't paid bill, invoiced => past_due
    end

    # Premium payment credit received and allocated to account
    event :advance_coverage_period, :after => :record_transition do
      transitions from: [:invoiced, :past_due, :delinquent], to: :current
      transitions from: :suspended, to: :current, :after => :reinstate_employer
    end

    # Premium payment reversed and account debited
    event :reverse_coverage_period, :after => [:revert_state, :record_transition] do
      transitions from: :binder_paid, to: :binder_pending, :guard => :before_plan_year_start
      transitions from: :binder_paid, to: :canceled
      transitions from: :current, to: :invoiced
      transitions from: :invoiced, to: :past_due
      transitions from: :past_due, to: :delinquent

      transitions from: :delinquent, to: :suspended
      # may 1 invoiced, may 10 paid(1), june 1 invoiced, june 5 paid(2), june 6 nsf(1)
    end

  end

private
  def record_transition
    self.workflow_state_transitions << WorkflowStateTransition.new(
      from_state: aasm.from_state,
      to_state: aasm.to_state,
      transition_at: Time.now.utc
    )
  end

  def latest_workflow_state_transition
    workflow_state_transitions.order_by(:'transition_at'.desc).limit(1).first
  end

  def first_day_of_month?
    TimeKeeper.date_of_record.day == 1
  end

  def late_notifications
    # TODO: implement this
  end

  def notify_hbx
  end

  def persist_state
    self.last_aasm_state = aasm.from_state
  end

  def revert_state
    self.aasm_state = last_aasm_state unless last_aasm_state.blank?
  end

  def enroll_employer
    employer_profile.enroll
  end

  def cancel_benefit
    employer_profile.benefit_canceled!
  end

  def suspend_benefit
    employer_profile.benefit_suspended!
  end

  def terminate_benefit
    employer_profile.benefit_terminated!
  end


end
