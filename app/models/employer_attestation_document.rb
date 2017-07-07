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
    state :rejected
    state :info_needed

    event :accept, :after => :record_transition do
      transitions from: :submitted, to: :accepted
    end

    event :reject, :after => :record_transition do
      transitions from: :submitted, to: :rejected
    end

    event :info_needed, :after => :record_transition do
      transitions from: :submitted, to: :info_needed
    end

    event :submit, :after => :record_transition do
      transitions from: :accepted, to: :submitted
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
    if [:info_needed, :rejected].include?(params[:status].to_sym)

      if params[:status].to_sym == :rejected
        self.reject!
      elsif params[:status].to_sym == :info_needed
        self.info_needed!
      end

      if params[:status].to_sym == :info_needed
        employer_attestation.set_pending! if employer_attestation.may_set_pending?
      else
        employer_attestation.deny! if employer_attestation.may_deny?
      end

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

  def approve_attestation
    if self.employer_attestation.may_approve?
      self.employer_attestation.approve!
    end
  end

  private

  def record_transition
    self.workflow_state_transitions << WorkflowStateTransition.new(
      from_state: aasm.from_state,
      to_state: aasm.to_state
    )
  end
end