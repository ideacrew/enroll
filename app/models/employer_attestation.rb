class EmployerAttestation
  include Mongoid::Document
  include SetCurrentUser
  include Mongoid::Timestamps
  include AASM

  embedded_in :employer_profile
  embeds_many :employer_attestation_documents, as: :documentable

  aasm do
    state :unsubmitted, initial: true
    state :submitted
    state :pending
    state :approved
    state :denied

    event :submit do 
      transitions from: :unsubmitted, to: :submitted
    end

    event :make_pending do
      transitions from: :submitted, to: :pending
    end

    event :approve do
      transitions from: [:submitted, :pending], to: :approved
    end

    event :deny do
      transitions from: [:submitted, :pending], to: :denied
    end
  end
end
