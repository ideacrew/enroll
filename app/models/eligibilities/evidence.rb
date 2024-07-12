# frozen_string_literal: true

module Eligibilities
  # A fact - usually obtained from an external service - that contributes to determining
  # whether a subject is eligible to make use of a benefit resource
  class Evidence
    include Mongoid::Document
    include Mongoid::Timestamps
    include AASM
    include ::EventSource::Command
    include GlobalID::Identification
    include Eligibilities::Eventable

    DUE_DATE_STATES = %w[review outstanding rejected].freeze

    ADMIN_VERIFICATION_ACTIONS = ["Verify", "Reject", "View History", "Call HUB", "Extend"].freeze

    VERIFY_REASONS = EnrollRegistry[:verification_reasons].item
    REJECT_REASONS = ["Illegible", "Incomplete Doc", "Wrong Type", "Wrong Person", "Expired", "Too old"].freeze

    OUTSTANDING_STATES = ['outstanding', 'rejected'].freeze

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
    embeds_many :workflow_state_transitions, class_name: "WorkflowStateTransition", as: :transitional, cascade_callbacks: true

    embeds_many :documents, class_name: "::Document", cascade_callbacks: true, as: :documentable do
      def uploaded
        @target.select(&:identifier)
      end
    end

    accepts_nested_attributes_for :documents, :request_results, :verification_histories, :workflow_state_transitions

    validates_presence_of :key, :is_satisfied, :aasm_state

    scope :by_name, ->(type_name) { where(:key => type_name) }

    alias applicant evidenceable

    def eligibility_event_name
      "events.individual.eligibilities.application.applicant.#{self.key}_evidence_updated"
    end

    # Requests a determination of the evidence's status from the Federal Data Services Hub (FDSH).
    #
    # @param action_name [String] The name of the action that triggered the request.
    # @param update_reason [String] The reason for the update.
    # @param updated_by [String, nil] The name of the user who updated the evidence.
    # @return [Boolean] `true` if the request was successful and the evidence's status was updated; `false` otherwise.
    def request_determination(action_name, update_reason, updated_by = nil)
      add_verification_history(action_name, update_reason, updated_by)

      response = Operations::Fdsh::RequestEvidenceDetermination.new.call(self)

      if response.failure?
        if EnrollRegistry.feature_enabled?(:validate_and_record_publish_application_errors)
          method_name = "determine_#{key.to_s.split('_').last}_evidence_aasm_status".to_sym
          send(method_name)

          update_reason = "#{key.to_s.titleize} Evidence Determination Request Failed due to #{response.failure}"
          add_verification_history("Hub Request Failed", update_reason, "system")
        end

        false
      else
        move_to_pending!
      end
    end

    # Sets the evidence's status to "attested" for the following types of evidence:
    ### :esi_mec, :non_esi_mec and :local_mec
    def determine_mec_evidence_aasm_status
      move_evidence_to_attested
    end

    # Sets the Income evidence's status to "outstanding" if the applicant is enrolled in any APTC or CSR enrollments;
    # otherwise, sets the evidence's status to "negative response".
    def determine_income_evidence_aasm_status
      family_id = applicant.application.family_id
      enrollments = HbxEnrollment.where(:aasm_state.in => HbxEnrollment::ENROLLED_STATUSES, family_id: family_id)
      aptc_or_csr_used = enrolled_in_any_aptc_csr_enrollments?(enrollments)

      if aptc_or_csr_used
        move_evidence_to_outstanding
      else
        move_evidence_to_negative_response_received
      end
    end

    def move_evidence_to_outstanding
      return unless may_move_to_outstanding?

      verification_document_due = EnrollRegistry[:verification_document_due_in_days].item
      due_date = due_on.blank? ? TimeKeeper.date_of_record + verification_document_due : due_on
      update(verification_outstanding: true, is_satisfied: false, due_on: due_date)
      move_to_outstanding!
    end

    def move_evidence_to_negative_response_received
      return unless may_negative_response_received?

      negative_response_received!
    end

    def move_evidence_to_attested
      update(verification_outstanding: false, is_satisfied: true, due_on: nil)
      attest!
    end

    # Checks if the applicant is enrolled in any APTC or CSR enrollments.
    #
    # @param applicant [Applicant] The applicant to check.
    # @param enrollments [Array<HbxEnrollment>] The enrollments to check.
    # @return [Boolean] `true` if the applicant is enrolled in any APTC or CSR enrollments; `false` otherwise.
    def enrolled_in_any_aptc_csr_enrollments?(enrollments)
      enrollments.any? do |enrollment|
        applicant_enrolled?(enrollment) &&
          enrollment.is_health_enrollment? &&
          (enrollment.applied_aptc_amount > 0 || ['02', '04', '05', '06'].include?(enrollment.product.csr_variant_id))
      end
    end

    def applicant_enrolled?(enrollment)
      enrollment.hbx_enrollment_members.any? { |member| member.applicant_id.to_s == applicant.family_member_id.to_s }
    end

    def payload_format
      case self.key
      when :non_esi_mec
        { non_esi_payload_format: EnrollRegistry[:non_esi_h31].setting(:payload_format).item }
      when :esi_mec
        { esi_mec_payload_format: EnrollRegistry[:esi_mec].setting(:payload_format).item }
      when :income
        { ifsv_payload_format: EnrollRegistry[:ifsv].setting(:payload_format).item }
      else
        {}
      end
    end

    def add_verification_history(action, update_reason, updated_by)
      result = self.verification_histories.build(action: action, update_reason: update_reason, updated_by: updated_by)
      self.save
      result
    end

    def extend_due_on(period = 30.days, updated_by = nil, action = 'extend_due_date')
      self.due_on = verif_due_date + period
      add_verification_history(action, "Extended due date to #{due_on.strftime('%m/%d/%Y')}", updated_by)
    end

    def auto_extend_due_on(period = 30.days, updated_by = nil)
      current = verif_due_date
      self.due_on = current + period
      add_verification_history('auto_extend_due_date', "Auto extended due date from #{current.strftime('%m/%d/%Y')} to #{due_on.strftime('%m/%d/%Y')}", updated_by)
    end

    def verif_due_date
      due_on || evidenceable.schedule_verification_due_on
    end

    # bypasses regular guards for changing the date
    def change_due_on!(new_date)
      self.due_on = new_date
    end

    def can_be_auto_extended?(date)
      return false unless due_on == date
      can_be_extended?('auto_extend_due_date')
    end

    def can_be_extended?(action)
      return false unless ['rejected', 'outstanding'].include?(self.aasm_state)
      extensions = verification_histories&.where(action: action)
      return true unless extensions&.any?
      #  want this limitation on due date extensions to reset anytime an evidence no longer requires a due date
      # (is moved to 'verified' or 'attested' state) so that an individual can benefit from the extension again in the future.
      auto_extend_time = extensions.last&.created_at
      return true unless auto_extend_time
      workflow_state_transitions.where(:to_state.in => ['verified', 'attested'], :created_at.gt => auto_extend_time).any?
    end

    # rubocop:disable Metrics/CyclomaticComplexity
    def has_determination_response?
      return false if pending?
      return true  if outstanding? || verified?

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
      state :unverified
      state :negative_response_received

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
        transitions from: :unverified, to: :attested
        transitions from: :negative_response_received, to: :attested
        transitions from: :attested, to: :attested
        transitions from: :verified, to: :attested
      end

      event :move_to_rejected, :after => [:record_transition] do
        transitions from: :pending, to: :rejected
        transitions from: :review, to: :rejected
        transitions from: :attested, to: :rejected
        transitions from: :verified, to: :rejected
        transitions from: :outstanding, to: :rejected
        transitions from: :unverified, to: :rejected
        transitions from: :negative_response_received, to: :rejected
        transitions from: :rejected, to: :rejected
      end

      event :negative_response_received, :after => [:record_transition] do
        transitions from: :pending, to: :negative_response_received
        transitions from: :attested, to: :negative_response_received
        transitions from: :verified, to: :negative_response_received
        transitions from: :review, to: :negative_response_received
        transitions from: :outstanding, to: :negative_response_received
        transitions from: :rejected, to: :negative_response_received
        transitions from: :unverified, to: :negative_response_received
        transitions from: :negative_response_received, to: :negative_response_received
      end

      event :move_to_unverified, :after => [:record_transition] do
        transitions from: :pending, to: :unverified
        transitions from: :attested, to: :unverified
        transitions from: :review, to: :unverified
        transitions from: :outstanding, to: :unverified
        transitions from: :verified, to: :unverified
        transitions from: :unverified, to: :unverified
        transitions from: :rejected, to: :unverified
        transitions from: :negative_response_received, to: :unverified
      end

      event :move_to_outstanding, :after => [:record_transition] do
        transitions from: :pending, to: :outstanding
        transitions from: :negative_response_received, to: :outstanding
        transitions from: :outstanding, to: :outstanding
        transitions from: :review, to: :outstanding
        transitions from: :attested, to: :outstanding
        transitions from: :verified, to: :outstanding
        transitions from: :unverified, to: :outstanding
        transitions from: :rejected, to: :outstanding
      end

      event :move_to_verified, :after => [:record_transition] do
        transitions from: :pending, to: :verified
        transitions from: :verified, to: :verified
        transitions from: :review, to: :verified
        transitions from: :attested, to: :verified
        transitions from: :outstanding, to: :verified
        transitions from: :unverified, to: :verified
        transitions from: :negative_response_received, to: :verified
        transitions from: :rejected, to: :verified
      end

      event :move_to_review, :after => [:record_transition] do
        transitions from: :pending, to: :review
        transitions from: :negative_response_received, to: :review
        transitions from: :review, to: :review
        transitions from: :outstanding, to: :review
        transitions from: :attested, to: :review
        transitions from: :verified, to: :review
        transitions from: :rejected, to: :review
        transitions from: :unverified, to: :review
      end

      event :move_to_pending, :after => [:record_transition] do
        transitions from: :attested, to: :pending
        transitions from: :pending, to: :pending
        transitions from: :review, to: :pending
        transitions from: :outstanding, to: :pending
        transitions from: :verified, to: :pending
        transitions from: :rejected, to: :pending
        transitions from: :unverified, to: :pending
        transitions from: :negative_response_received, to: :pending
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
        to_state: aasm.to_state,
        event: aasm.current_event
      )
    end

    def type_unverified?
      !type_verified?
    end

    def is_previous_state?(state)
      workflow_state_transitions.order_by(:transition_at.desc)&.first&.from_state == state
    end

    def type_verified?
      ["verified", "attested"].include? aasm_state
    end

    def is_type_outstanding?
      aasm_state == "outstanding"
    end

    def clone_embedded_documents(new_evidence)
      clone_verification_histories(new_evidence)
      clone_request_results(new_evidence)
      clone_workflow_state_transitions(new_evidence)
      clone_documents(new_evidence)
    end

    private

    def clone_verification_histories(new_evidence)
      verification_histories.each do |verification|
        verification_attrs = verification.attributes.deep_symbolize_keys.slice(:action, :modifier, :update_reason, :updated_by, :is_satisfied, :verification_outstanding, :due_on, :aasm_state, :date_of_action)
        new_evidence.verification_histories.build(verification_attrs)
      end
    end

    def clone_request_results(new_evidence)
      request_results.each do |request_result|
        request_result_attrs = request_result.attributes.deep_symbolize_keys.slice(:result, :source, :source_transaction_id, :code, :code_description, :raw_payload, :date_of_action)
        new_evidence.request_results.build(request_result_attrs)
      end
    end

    def clone_workflow_state_transitions(new_evidence)
      workflow_state_transitions.each do |wfst|
        wfst_attrs = wfst.attributes.deep_symbolize_keys.slice(:event, :from_state, :to_state, :transition_at, :reason, :comment, :user_id)
        new_evidence.workflow_state_transitions.build(wfst_attrs)
      end
    end

    def clone_documents(new_evidence)
      documents.each do |document|
        document_attrs = document.attributes.deep_symbolize_keys.slice(:title, :creator, :subject, :description, :publisher, :contributor, :date, :type, :format,
                                                                       :identifier, :source, :language, :relation, :coverage, :rights, :tags, :size, :doc_identifier)
        new_evidence.documents.build(document_attrs)
      end
    end
  end
end
