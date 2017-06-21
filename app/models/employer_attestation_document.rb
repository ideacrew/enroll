class EmployerAttestationDocument
  include Mongoid::Document
  include SetCurrentUser
  include Mongoid::Timestamps
  include AASM

  embedded_in :employer_attestation
  embeds_one :document, as: :documentable

  aasm do
    state :submitted, initial: true
    state :accepted
    state :rejected

    event :accept do
      transitions from: :submitted, to: :accepted
    end

    event :reject do
      transitions from: :submitted, to: :rejected
    end
  end
end