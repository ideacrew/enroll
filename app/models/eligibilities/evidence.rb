# frozen_string_literal: true

module Eligibilities
  # A fact - usually obtained from an external service - that contributes to determining
  # whether a subject is eligible to make use of a benefit resource
  class Evidence
    include Mongoid::Document
    include Mongoid::Timestamps
    include AASM
    include ::EventSource::Command
    include Dry::Monads[:result, :do, :try]
    include GlobalID::Identification
    include Eligibilities::Eventable

    DUE_DATE_STATES = %w[review outstanding].freeze

    ADMIN_VERIFICATION_ACTIONS = ["Verify", "Reject", "View History", "Call HUB", "Extend"].freeze

    VERIFY_REASONS = EnrollRegistry[:verification_reasons].item
    REJECT_REASONS = ["Illegible", "Incomplete Doc", "Wrong Type", "Wrong Person", "Expired", "Too old"].freeze

    FDSH_EVENTS = {
      :esi_mec => 'events.fdsh.evidences.esi_determination_requested',
      :non_esi_mec => 'events.fdsh.evidences.non_esi_determination_requested',
      :income => 'events.fti.evidences.ifsv_determination_requested',
      :local_mec => "events.iap.mec_check.mec_check_requested"
    }.freeze

    embedded_in :evidenceable, polymorphic: true

    field :key, type: Symbol
    field :title, type: String
    field :description, type: String

    field :received_at, type: DateTime, default: -> { Time.now }
    field :is_satisfied, type: Boolean, default: false
    field :verification_outstanding, type: Boolean, default: false

    field :aasm_state, type: String
    field :update_reason, type: String
    field :due_on, type: Date
    field :external_service, type: String
    field :updated_by, type: String

    embeds_many :verification_histories, class_name: "::Eligibilities::VerificationHistory", cascade_callbacks: true
    embeds_many :request_results, class_name: "::Eligibilities::RequestResult", cascade_callbacks: true
    embeds_many :workflow_state_transitions, class_name: "WorkflowStateTransition", as: :transitional

    embeds_many :documents, class_name: "::Document", cascade_callbacks: true, as: :documentable do
      def uploaded
        @target.select(&:identifier)
      end
    end

    accepts_nested_attributes_for :documents, :request_results, :verification_histories, :workflow_state_transitions

    validates_presence_of :key, :is_satisfied, :aasm_state

    scope :by_name, ->(type_name) { where(:key => type_name) }

    def eligibility_event_name
      "events.individual.eligibilities.application.applicant.#{self.key}_evidence_updated"
    end

    def request_determination(action_name, update_reason, updated_by = nil)
      application = self.evidenceable.application
      payload = construct_payload(application)
      headers = self.key == :local_mec ? { payload_type: 'application' } : { correlation_id: application.id }

      request_event = event(FDSH_EVENTS[self.key], attributes: payload.to_h, headers: headers)
      return false unless request_event.success?
      response = request_event.value!.publish

      if response
        add_verification_history(action_name, update_reason, updated_by)
        self.save
      end
      response
    end

    def add_verification_history(action, update_reason, updated_by)
      self.verification_histories.build(action: action, update_reason: update_reason, updated_by: updated_by)
    end

    def construct_payload(application)
      cv3_application = FinancialAssistance::Operations::Applications::Transformers::ApplicationTo::Cv3Application.new.call(application).value!
      AcaEntities::MagiMedicaid::Operations::InitializeApplication.new.call(cv3_application).value!
    end

    def extend_due_on(period = 30.days, updated_by = nil)
      self.due_on = verif_due_date + period
      add_verification_history('extend_due_date', "Extended due date to #{due_on.strftime('%m/%d/%Y')}", updated_by)
      self.save
    end

    def verif_due_date
      due_on || evidenceable.schedule_verification_due_on
    end

    # bypasses regular guards for changing the date
    def change_due_on!(new_date)
      self.due_on = new_date
    end

    # rubocop:disable Metrics/CyclomaticComplexity
    def has_determination_response?
      return false if pending?
      return true  if outstanding? || verified? || non_verified?

      if review?
        transitions = workflow_state_transitions.where(:to_state => 'review').order("transition_at DESC")

        from_pending = transitions.detect{|transition| transition.from_state == 'pending'}
        if from_pending
          return true if request_results.where(:created_at.gte => from_pending.transition_at).present?
          return false
        end

        from_outstanding = transitions.detect{|transition| transition.from_state == 'outstanding'}
        return true if from_outstanding
      end

      if attested?
        request_history = verification_histories.where(:action.in => ['application_determined', 'call_hub']).last

        if request_history
          return true if request_results.where(:created_at.gte => request_history.created_at).present?
          return false
        end
      end

      request_results.present? ? true : false
    end
    # rubocop:enable Metrics/CyclomaticComplexity

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
      state :rejected

      event :attest, :after => [:record_transition] do
        transitions from: :pending, to: :attested
        transitions from: :attested, to: :attested
        transitions from: :review, to: :attested
        transitions from: :outstanding, to: :attested
        transitions from: :rejected, to: :attested
        transitions from: :attested, to: :attested
      end

      event :move_to_rejected, :after => [:record_transition] do
        transitions from: :pending, to: :rejected
        transitions from: :review, to: :rejected
        transitions from: :attested, to: :rejected
        transitions from: :verified, to: :rejected
        transitions from: :outstanding, to: :rejected
        transitions from: :rejected, to: :rejected
      end

      event :move_to_outstanding, :after => [:record_transition] do
        transitions from: :pending, to: :outstanding
        transitions from: :outstanding, to: :outstanding
        transitions from: :review, to: :outstanding
        transitions from: :attested, to: :outstanding
        transitions from: :verified, to: :outstanding
        transitions from: :rejected, to: :outstanding
      end

      event :move_to_verified, :after => [:record_transition] do
        transitions from: :pending, to: :verified
        transitions from: :verified, to: :verified
        transitions from: :review, to: :verified
        transitions from: :attested, to: :verified
        transitions from: :outstanding, to: :verified
        transitions from: :rejected, to: :verified
      end

      event :move_to_review, :after => [:record_transition] do
        transitions from: :pending, to: :review
        transitions from: :review, to: :review
        transitions from: :outstanding, to: :review
        transitions from: :attested, to: :review
        transitions from: :verified, to: :review
        transitions from: :rejected, to: :review
      end

      event :move_to_pending, :after => [:record_transition] do
        transitions from: :attested, to: :pending
        transitions from: :pending, to: :pending
        transitions from: :review, to: :pending
        transitions from: :outstanding, to: :pending
        transitions from: :verified, to: :pending
        transitions from: :rejected, to: :pending
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

    def is_type_outstanding?
      aasm_state == "outstanding"
    end
  end
end
