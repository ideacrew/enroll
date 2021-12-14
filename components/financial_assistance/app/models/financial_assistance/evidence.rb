# frozen_string_literal: true

module FinancialAssistance
  #Evidences for an applicant to detrmine his status
  class Evidence
    include Mongoid::Document
    include Mongoid::Timestamps
    include AASM
    include ::EventSource::Command

    DUE_DATE_STATES = %w[review outstanding].freeze

    VERIFY_REASONS = EnrollRegistry[:verification_reasons].item
    #add them to registry
    REJECT_REASONS = ["Illegible", "Incomplete Doc", "Wrong Type", "Wrong Person", "Expired", "Too old"].freeze

    FDSH_EVENTS = {
      :non_esi_mec => 'fdsh.evidences.esi_determination_requested',
      :esi_mec => 'fdsh.evidences.non_esi_determination_requested',
      :income => 'fti.evidences.ifsv_determination_requested',
      :aces_mec => "iap.mec_check.mec_check_requested"
    }.freeze

    # embedded_in :applicant, class_name: '::FinancialAssistance::Applicant'

    embedded_in :evidencable, polymorphic: true

    field :key, type: Symbol
    field :title, type: String
    field :description, type: String

    field :received_at, type: DateTime, default: -> { Time.now }
    field :is_satisfied, type: Boolean, default: false
    field :verification_outstanding, type: Boolean, default: false

    field :aasm_state, type: Symbol
    field :update_reason, type: String
    field :due_on, type: Date
    field :external_service, type: String
    field :updated_by, type: String

    embeds_one :verification_status, class_name: "::FinancialAssistance::VerificationStatus"
    embeds_many :verification_history, class_name: "::FinancialAssistance::VerificationHistory"
    embeds_many :request_results, class_name: "::FinancialAssistance::EligibilityResult"

    embeds_many :documents, as: :documentable do
      def uploaded
        @target.select(&:identifier)
      end
    end

    embeds_many :workflow_state_transitions, class_name: "WorkflowStateTransition", as: :transitional

    validates_presence_of :key, :is_satisfied, :aasm_state

    scope :by_name, ->(type_name) { where(:key => type_name) }
    default_scope ->{ exists(key: true) }


    def request_determination
      application = self.applicant.application
      payload = construct_payload(application)
      event(FDSH_EVENTS[self.key], attributes: payload.to_h, headers: { correlation_id: application.id })
    end

    def construct_payload(application)
      cv3_application = FinancialAssistance::Operations::Applications::Transformers::ApplicationTo::Cv3Application.new.call(application).value!
      AcaEntities::MagiMedicaid::Operations::InitializeApplication.new.call(cv3_application).value!
    end

    def extend_due_on(date = (TimeKeeper.datetime_of_record + 30.days))
      self.due_on = date
    end

    PENDING = [:pending, :attested].freeze
    OUTSTANDING = [:outstanding, :review, :errored].freeze
    CLOSED = [:denied, :closed, :expired].freeze
    aasm do
      state :attested, initial: true
      state :pending
      state :review
      state :outstanding
      state :verified
      state :non_verified

      state :determined
      state :expired
      state :denied
      state :errored
      state :closed

      state :corrected

      event :attest, :after => [:record_transition] do
        transitions from: :pending, to: :attested
        transitions from: :attested, to: :attested
        transitions from: :review, to: :attested
        transitions from: :outstanding, to: :attested
        transitions from: :attested, to: :attested
      end

      event :move_to_outstanding, :after => [:record_transition] do
        transitions from: :pending, to: :outstanding
        transitions from: :outstanding, to: :outstanding
        transitions from: :review, to: :outstanding
        transitions from: :attested, to: :outstanding
        transitions from: :verified, to: :outstanding
      end

      event :move_to_verified, :after => [:record_transition] do
        transitions from: :pending, to: :verified
        transitions from: :verified, to: :verified
        transitions from: :review, to: :verified
        transitions from: :attested, to: :verified
        transitions from: :outstanding, to: :verified
      end

      event :move_to_review, :after => [:record_transition] do
        transitions from: :pending, to: :review
        transitions from: :review, to: :review
        transitions from: :outstanding, to: :review
        transitions from: :attested, to: :review
        transitions from: :verified, to: :review
      end

      event :move_to_pending, :after => [:record_transition] do
        transitions from: :attested, to: :pending
        transitions from: :pending, to: :pending
        transitions from: :review, to: :pending
        transitions from: :outstanding, to: :pending
        transitions from: :verified, to: :pending
      end

      event :determined, :after => [:record_transition] do
        transitions from: :requested, to: :determined
        transitions from: :review_required, to: :determined
        transitions from: :corrected, to: :determined
      end

      event :expired, :after => [:record_transition] do
        transitions from: :requested, to: :expired
      end

      event :denied, :after => [:record_transition] do
        transitions from: :requested, to: :denied
      end

      event :errored, :after => [:record_transition] do
        transitions from: :requested, to: :errored
        transitions from: :errored, to: :errored
        transitions from: :corrected, to: :errored
      end

      event :corrected, :after => [:record_transition] do
        transitions from: :errored, to: :corrected
      end

      event :closed, :after => [:record_transition] do
        transitions from: :pending, to: :closed
        transitions from: :requested, to: :closed
        transitions from: :review_required, to: :closed
        transitions from: :expired, to: :closed
        transitions from: :denied, to: :closed
        transitions from: :errored, to: :closed
        transitions from: :closed, to: :closed
      end
    end

    def record_transition
      self.workflow_state_transitions << WorkflowStateTransition.new(
        from_state: aasm.from_state,
        to_state: aasm.to_state
      )
    end

    def type_unverified?
      !type_verified?
    end

    def type_verified?
      ["verified", "attested"].include? aasm_state
    end

    def verif_due_date
      due_on || TimeKeeper.date_of_record + 95.days
    end

    def add_verification_history(params)
      verification_history << FinancialAssistance::VerificationHistory.new(params)
    end
  end
end