class EmployerAttestationDocument < Document
  include Mongoid::Document
  include SetCurrentUser
  include Mongoid::Timestamps
  include AASM

  REASON_KINDS = [
    "Unable To Open Document",
    "Document Not Required DOR-1 Form",
    "DOR-1 Form DoesNot Match Bussiness",
    "Other Reason"
  ]

  field :aasm_state, type: String, default: "submitted"
  field :reason_for_rejection, type: String

  embedded_in :employer_attestation
  embeds_many :workflow_state_transitions, as: :transitional

  aasm do
    state :submitted, initial: true
    state :accepted, :after_enter => :approve_attestation
    state :rejected, :after_enter => :deny_attestation

    event :accept, :after => :record_transition do
      transitions from: :submitted, to: :accepted
    end

    event :reject, :after => :record_transition do
      transitions from: :submitted, to: :rejected
    end
  end
 
  def employer_profile
    org = Organization.where(:"employer_profile.employer_attestation.employer_attestation_documents._id" => BSON::ObjectId.from_string(self.id)).first
    org.employer_profile
  end

  def employer_attestation
    employer_profile.employer_attestation
  end

  def submit_review(params)
    if [:info_needed, :pending].include?(params[:status].to_sym)
      self.reject! if self.may_reject?
      employer_attestation.set_pending! if params[:status].to_sym == :info_needed && employer_attestation.may_set_pending?
      add_reason_for_rejection(params)
    elsif params[:status].to_sym == :accepted
      self.accept! if self.may_accept?
    end
  end

  def add_reason_for_rejection(params)
    if params[:reason_for_rejection].present?
      reason_for_reject = (params[:reason_for_rejection] == "Other Reason") ? params[:other_reason] : params[:reason_for_rejection]
      self.update(reason_for_rejection: reason_for_reject)
    end
  end

  private

  def approve_attestation
    if self.employer_attestation.may_approve?
      self.employer_attestation.approve!
    end
  end

  def deny_attestation
    if self.employer_attestation.may_deny?
      self.employer_attestation.deny!
    end
  end

  def record_transition
    self.workflow_state_transitions << WorkflowStateTransition.new(
      from_state: aasm.from_state,
      to_state: aasm.to_state
    )
  end
end