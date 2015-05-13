class PremiumStatement
  include Mongoid::Document
  include Mongoid::Timestamps
  include AASM

  embedded_in :employer_profile

  # Payment status
  field :effective_on, type: Date
  field :last_premium_paid_on, type: Date
  field :last_premium_amount, type: Money
  field :next_premium_due_on, type: Date
  field :next_premium_amount, type: Money

  field :aasm_state, type: String
  field :last_aasm_state, type: String

  validates_presence_of :effective_on

  def notify_hbx
  end

  def persist_state
    self.last_aasm_state = aasm.from_state
  end

  def revert_state
    self.aasm_state = last_aasm_state unless last_aasm_state.blank?
  end

  ## TODO -- reconcile the need for history via embeds_many with the state machine functionality
  aasm do
    state :binder_pending, initial: true  # Initial open enrollment period closed, first premium payment not received/processed
    state :binder_paid
    state :canceled                       # Coverage never took effect    
    state :current                        # Enrolled and premium payment up-to-date
    state :overdue                        # Premium payment 1-29 days past due
    state :late                           # Premium payment 30-60 days past due - send notices to employees
    state :suspended                      # Premium payment 61-90 - transmit terms to carriers with retro date
    state :terminated                     # Premium payment > 90 days past due (day 91) or Employer voluntarily terminates

    event :advance_billing_period do
      # transitions from: [:current, :overdue, :late, :suspended, :terminated], to: [:current, :overdue, :late, :suspended, :terminated]
      transitions from: :binder_pending, to: :binder_pending
      transitions from: :binder_paid, to: :overdue
      transitions from: :current, to: :overdue
      transitions from: :overdue, to: :late
      transitions from: :late, to: :suspended
      transitions from: :suspended, to: :terminated
    end

    # Premium payment credit received and allocated to account
    event :advance_coverage_period do
      transitions from: :binder_pending, to: :binder_paid
      transitions from: [:binder_paid, :current, :overdue, :late, :suspended, :terminated], to: :current, :after => :persist_state
    end

    # Premium payment reversed and account debited
    event :reverse_coverage_period, :after => :revert_state do
      transitions from: :binder_paid, to: :canceled
      transitions from: :current, to: :overdue
      transitions from: :overdue, to: :late
      transitions from: :late, to: :suspended
      transitions from: :suspended, to: :terminated
    end

    event :cancel_coverage do
      transitions from: :binder_pending, to: :canceled
    end

    event :terminate_coverage do
      transitions from: [:current, :overdue, :late, :suspended], to: :terminated
    end

    event :reinstate_coverage do
      transitions from: :terminated, to: :current
    end
  end


end
