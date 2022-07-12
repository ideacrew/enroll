class LawfulPresenceDetermination
  SSA_VERIFICATION_REQUEST_EVENT_NAME = "local.enroll.lawful_presence.ssa_verification_request"
  VLP_VERIFICATION_REQUEST_EVENT_NAME = "local.enroll.lawful_presence.vlp_verification_request"

  include Mongoid::Document
  include Mongoid::Timestamps
  include AASM
  include Acapi::Notifiers
  include Mongoid::Attributes::Dynamic
  include Mongoid::History::Trackable
  include EventSource::Command

  embedded_in :ivl_role, polymorphic: true
  embeds_many :ssa_responses, class_name:"EventResponse"
  embeds_many :vlp_responses, class_name:"EventResponse"
  embeds_many :ssa_requests, class_name:"EventRequest"
  embeds_many :vlp_requests, class_name:"EventRequest"

  field :vlp_verified_at, type: DateTime
  field :vlp_authority, type: String
  field :vlp_document_id, type: String
  field :citizen_status, type: String
  field :citizenship_result, type: String
  field :qualified_non_citizenship_result, type:  String
  field :aasm_state, type: String
  embeds_many :workflow_state_transitions, as: :transitional

  after_create :publish_created_event
  after_update :publish_updated_event

  track_history :modifier_field_optional => true,
                :on => [:vlp_verified_at,
                        :vlp_authority,
                        :citizen_status,
                        :citizenship_result,
                        :aasm_state],
                :scope => :consumer_role,
                :track_create  => false,    # track document creation, default is false
                :track_update  => true,    # track document updates, default is true
                :track_destroy => false     # track document destruction, default is false

  aasm do
    state :verification_pending, initial: true
    state :verification_outstanding
    state :verification_successful

    event :authorize, :after => :record_transition do
      transitions from: :verification_pending, to: :verification_successful, after: :record_approval_information
      transitions from: :verification_outstanding, to: :verification_successful, after: :record_approval_information
      transitions from: :verification_successful, to: :verification_successful, after: :record_approval_information
    end

    event :deny, :after => :record_transition do
      transitions from: :verification_pending, to: :verification_outstanding, after: :record_denial_information
      transitions from: :verification_outstanding, to: :verification_outstanding, after: :record_denial_information
      transitions from: :verification_successful, to: :verification_outstanding, after: :record_denial_information
    end

    event :revert, :after => :record_transition do
      transitions from: :verification_pending, to: :verification_pending, after: :record_denial_information
      transitions from: :verification_outstanding, to: :verification_pending, after: :record_denial_information
      transitions from: :expired, to: :verification_pending
      transitions from: :verification_successful, to: :verification_pending
    end
  end

  def latest_denial_date
    responses = (ssa_responses.to_a + vlp_responses.to_a)
    if self.verification_outstanding? && responses.present?
      responses.max_by(&:received_at).received_at
    else
      nil
    end
  end

  def start_ssa_process
    if EnrollRegistry.feature_enabled?(:ssa_h3)
      Operations::Fdsh::Ssa::H3::RequestSsaVerification.new.call(self.ivl_role.person)
    else
      notify(SSA_VERIFICATION_REQUEST_EVENT_NAME, {:person => self.ivl_role.person})
    end
  end

  def start_vlp_process(requested_start_date)
    if EnrollRegistry.feature_enabled?(:vlp_h92)
      Operations::Fdsh::Vlp::H92::RequestInitialVerification.new.call(self.ivl_role.person)
    else
      notify(VLP_VERIFICATION_REQUEST_EVENT_NAME, {:person => self.ivl_role.person, :coverage_start_date => requested_start_date})
    end
  end

  def assign_citizen_status(new_status)
    update_attributes(citizen_status: new_status)
  end

  private
  def record_approval_information(*args)
    approval_information = args.first
    self.update_attributes!(vlp_verified_at: approval_information.determined_at,
                            vlp_authority: approval_information.vlp_authority)

    self.qualified_non_citizenship_result = approval_information.qualified_non_citizenship_result if approval_information.qualified_non_citizenship_result
    if approval_information.citizenship_result
      self.citizenship_result = approval_information.citizenship_result
    else
      self.ivl_role.is_native? ? self.citizenship_result = "us_citizen" : self.citizenship_result = "non_native_citizen"
    end
    if ["ssa", "curam"].include?(approval_information.vlp_authority)
      if self.ivl_role
        if self.ivl_role.person
          unless self.ivl_role.person.ssn.blank?
            self.ivl_role.ssn_validation = "valid"
            self.ivl_role.person.verification_types.active.where(type_name:"Social Security Number").first.validation_status = "verified"
          end
        end
      end
    end
  end

  def record_denial_information(*args)
    denial_information = args.first
    qnc_result = denial_information.qualified_non_citizenship_result.present? ? denial_information.qualified_non_citizenship_result : nil
    self.update_attributes!(vlp_verified_at: denial_information.determined_at,
                            vlp_authority: denial_information.vlp_authority,
                            qualified_non_citizenship_result: qnc_result,
                            citizenship_result: ::ConsumerRole::NOT_LAWFULLY_PRESENT_STATUS)
  end

  def publish_created_event
    attrs = { consumer_role_id: ivl_role.id }.merge!(self.changes)
    # TODO: This should be refactored to use created instead of updated.
    event = event('events.individual.consumer_roles.lawful_presence_determinations.updated', attributes: attrs)
    event.success.publish if event.success?
  rescue StandardError => e
    Rails.logger.error { "Couldn't publish lawful presence determination update event due to #{e.backtrace}" }
  end

  def publish_updated_event
    attrs = { consumer_role_id: ivl_role.id }.merge!(self.changes)
    event = event('events.individual.consumer_roles.lawful_presence_determinations.updated', attributes: attrs)
    event.success.publish if event.success?
  rescue StandardError => e
    Rails.logger.error { "Couldn't generate lawful presence determination update event due to #{e.backtrace}" }
  end

  def record_transition(*args)
    workflow_state_transitions << WorkflowStateTransition.new(
      from_state: aasm.from_state,
      to_state: aasm.to_state,
      event: aasm.current_event,
      transition_at: Time.now
    )
  end
end
