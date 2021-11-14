# frozen_string_literal: true

module Eligibilities
  # A fact - usually obtained from an external service - that contributes to determining
  # whether a subject is eligible to make use of a benefit resource
  class Evidence
    include Mongoid::Document
    include Mongoid::Timestamps
    include AASM

    field :key, type: Symbol
    field :title, type: String
    field :description, type: String

    field :received_at, type: DateTime, default: -> { Time.now }
    field :is_satisfied, type: Boolean, default: false
    field :verification_outstanding, type: Boolean, default: false
    field :aasm_state, type: String
    field :updated_by, type: String

    embedded_in :eligibility, class_name: 'Eligibilities::Eligibility'

    # The service or aquthority that provided the fact
    embeds_one :evidence_source, class_name: 'Eligibilities::EvidenceSource'

    # embeds_many :eligibility_results, class_name: '::FinancialAssistance::EligibilityResult'

    # embeds_one :evidence_exception_workflow, class_name: 'Eligibilities::EvidenceExceptionWorkflow'
    # accepts_nested_attributes_for :evidence_exception_workflows

    # embeds_one :verification_status, class_name: '::FinancialAssistance::VerificationStatus'
    # embeds_many :verification_history, class_name: '::FinancialAssistance::VerificationHistory'

    validates_presence_of :key, :is_satisfied, :verification_outstanding, :aasm_state

    # embeds_many :documents, as: :documentable do
    #   def uploaded
    #     @target.select(&:identifier)
    #   end
    # end

    aasm do
      state :pending, initial: true
      state :requested
      state :determined
      state :review_required
      state :expired
      state :rejected
      state :errored
      state :corrected
      state :closed

      event :requested do
        transitions from: :pending, to: :requested
        transitions from: :requested, to: :requested
        transitions from: :review_required, to: :requested
        transitions from: :expired, to: :requested
        transitions from: :rejected, to: :requested
        transitions from: :errored, to: :requested
      end

      event :review_required do
        transitions from: :requested, to: :review_required
        transitions from: :review_required, to: :review_required
        transitions from: :errored, to: :review_required
      end

      event :determined do
        transitions from: :requested, to: :determined
        transitions from: :review_required, to: :determined
        transitions from: :corrected, to: :determined
      end

      event :expired do
        transitions from: :requested, to: :expired
      end

      event :rejected do
        transitions from: :requested, to: :rejected
      end

      event :errored do
        transitions from: :requested, to: :errored
        transitions from: :errored, to: :errored
        transitions from: :corrected, to: :errored
      end

      event :corrected do
        transitions from: :errored, to: :corrected
      end

      event :closed do
        transitions from: :pending, to: :closed
        transitions from: :requested, to: :closed
        transitions from: :review_required, to: :closed
        transitions from: :expired, to: :closed
        transitions from: :rejected, to: :closed
        transitions from: :errored, to: :closed
        transitions from: :closed, to: :closed
      end
    end
  end
end
