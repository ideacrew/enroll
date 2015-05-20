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

  ## TODO -- reconcile the need for history via embeds_many with the state machine functionality
  aasm do
    # Initial open enrollment period closed, first premium payment not received/processed
    state :binder_pending, initial: true  
    state :binder_paid, :after_enter => :enroll_employer

    # Enrolled and premium payment up-to-date
    state :current 

    # Premium payment 1-29 days past due
    state :overdue

    # Premium payment 30-60 days past due - send notices to employees
    state :late

    # Premium payment 61-90 - transmit terms to carriers with retro date   
    state :suspended,   :after_enter => :suspend_employer    

    # Premium payment > 90 days past due (day 91) or Employer voluntarily terminates
    state :terminated,  :after_enter => :terminate_employer  

    # Coverage never took effect, either voluntarily withdrawal or not paying binder
    state :canceled,    :after_enter => :cancel_employer

    # Signal parent Employer Profile
    event :allocate_binder_payment do
      transitions from: :binder_pending, to: :binder_paid
    end

    event :advance_billing_period do
      # transitions from: [:current, :overdue, :late, :suspended, :terminated], to: [:current, :overdue, :late, :suspended, :terminated]
      transitions from: :binder_pending, to: :canceled
      transitions from: :binder_paid, to: :overdue
      transitions from: :current, to: :overdue
      transitions from: :overdue, to: :late
      transitions from: :late, to: :suspended
      transitions from: :suspended, to: :terminated
    end

    # Premium payment credit received and allocated to account
    event :advance_coverage_period do
      transitions from: [:binder_paid, :current, :overdue, :late, :suspended], 
                  to: :current, :after => [:persist_state, :reinstate_employer]
    end

    # Premium payment reversed and account debited
    event :reverse_coverage_period, :after => :revert_state do
      transitions from: :binder_paid, to: :canceled
      transitions from: :current, to: :overdue
      transitions from: :overdue, to: :late
      transitions from: :late, to: :suspended
    end

    event :cancel_coverage do
      transitions from: :binder_pending, to: :canceled
    end

    event :suspend_coverage do
      transitions from: [:current, :late, :overdue], to: :suspended
    end

    event :terminate_coverage do
      transitions from: :suspended, to: :terminated
    end

    event :reinstate_coverage do
      transitions from: :suspended, to: :current
    end

  end


end
