class EmployerProfileAccount
  include Mongoid::Document
  include Mongoid::Timestamps
  include AASM

  embedded_in :employer_profile

  field :next_premium_due_on, type: Date
  field :next_premium_amount, type: Money
  field :aasm_state, type: String

  embeds_many :premium_payments
  embeds_many :workflow_state_transitions, as: :transitional

  accepts_nested_attributes_for :premium_payments

  validates_presence_of :next_premium_due_on, :next_premium_amount

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
    state :prepaid
    state :current
    state :past_due                                          # Premium payment 1-29 days past due
    state :delinquent,  :after_enter => :late_notifications  # Premium payment 30-60 days past due - send notices to employees
    state :suspended,   :after_enter => :suspend_plan_year   # Premium payment 61-90 - transmit terms to carriers with retro date   

    state :canceled,    :after_enter => :cancel_employer     # Coverage never took effect, either voluntarily withdrawal or not paying binder
    state :terminated,  :after_enter => [:terminate_employer, :terminate_plan_year] # Premium payment > 90 days past due (day 91) or Employer voluntarily terminates

    # Signal parent Employer Profile
    event :allocate_binder_payment do
      transitions from: :binder_pending, to: :binder_paid
    end

    # TODO Advance billing period on binder_pending in middle of month
    event :advance_billing_period, :guard => :first_day_of_month? do
      transitions from: :binder_pending, to: :canceled
      transitions from: :binder_paid, to: :current
      transitions from: :prepaid, to: :current
      transitions from: :current, to: :past_due
      transitions from: :past_due, to: :delinquent
      transitions from: :delinquent, to: :suspended
      transitions from: :suspended, to: :terminated
    end

    # Premium payment credit received and allocated to account
    event :advance_coverage_period, :after => :record_transition do
      transitions from: [:binder_pending, :current], to: :prepaid
      transitions from: [:binder_paid, :suspended],  to: :current, :after => :reinstate_employer
      transitions from: [:current, :past_due, :delinquent], to: :current
    end

    # Premium payment reversed and account debited
    event :reverse_coverage_period, :after => [:revert_state, :record_transition] do
      transitions from: :binder_paid, to: :canceled
      transitions from: :current, to: :past_due
      transitions from: :past_due, to: :delinquent
      transitions from: :delinquent, to: :suspended
    end

    event :cancel_coverage, :after => :record_transition do
      transitions from: :binder_pending, to: :canceled
    end

    event :suspend_coverage, :after => :record_transition do
      transitions from: [:current, :delinquent, :past_due], to: :suspended
    end

    event :reinstate_coverage, :after => :record_transition do
      transitions from: :suspended, to: :current
    end

    event :terminate_coverage, :after => :record_transition do
      transitions from: :suspended, to: :terminated
    end

    event :reapply, :after => :record_transition do
      transitions from: :terminated, to: :binder_pending
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

  def reinstate_employer
    employer_profile.reinstate_coverage
  end

  def suspend_employer
    employer_profile.suspend_coverage
  end

  def cancel_employer
    employer_profile.cancel_coverage
  end

  def terminate_employer
    employer_profile.terminate_coverage
  end

end
