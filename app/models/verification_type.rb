class VerificationType
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::History::Trackable
  include Eligibilities::Visitors::Visitable
  include GlobalID::Identification

  embedded_in :person

  LOCATION_RESIDENCY = EnrollRegistry[:enroll_app].setting(:state_residency).item

  # @!macro [new] constant
  #   @!attribute [r] $0
  #   @return [Array<String>] an array of all verification types.

  # List of all verification types
  # @todo Remove LOCATION_RESIDENCY and add it conditionally when
  # `EnrollRegistry.feature_enabled?(:location_residency_verification_type)` is true as
  # it is only applicable in DC context.
  ALL_VERIFICATION_TYPES = [
    LOCATION_RESIDENCY,
    "Social Security Number",
    "American Indian Status",
    "Citizenship",
    "Immigration status",
    'Alive Status'
  ].freeze

  ALIVE_STATUS = 'Alive Status'.freeze

  ADMIN_CALL_HUB_VERIFICATION_TYPES = ALL_VERIFICATION_TYPES - ["Alive Status", "American Indian Status"].freeze

  NON_CITIZEN_IMMIGRATION_TYPES = [LOCATION_RESIDENCY, "Social Security Number", "American Indian Status"].freeze
  VALIDATION_STATES = %w[na unverified pending review outstanding verified attested expired curam rejected].freeze
  OUTSTANDING_STATES = %w[outstanding rejected].freeze
  DUE_DATE_STATES = %w[review outstanding rejected].freeze
  SATISFIED_STATES = %w[verified attested valid curam].freeze
  NEGATIVE_STATES = %w[negative_response_received].freeze


  field :type_name, type: String
  field :validation_status, type: String
  field :applied_roles, type: Array, default: ["consumer_role"] #[consumer_role, resident_role, ...]
  field :update_reason, type: String
  field :rejected, type: Boolean
  field :external_service, type: String
  field :due_date, type: Date
  field :due_date_type, type: String # admin, notice
  field :updated_by
  field :inactive, type: Boolean #use this field (assign true) only if type was present but for some reason if is not applicable anymore

  track_history :on => [:fields],
                :scope => :person,
                :modifier_field => :modifier,
                :modifier_field_optional => true,
                :version_field => :tracking_version,
                :track_create => true,    # track document creation, default is false
                :track_update => true,    # track document updates, default is true
                :track_destroy => true

  scope :active, -> { where(:inactive.ne => true) }
  scope :by_name, ->(type_name) { where(:type_name => type_name) }
  scope :ssn_type, -> { by_name("Social Security Number").active }
  scope :citizenship_type, -> { by_name("Citizenship").active }
  scope :alive_status_type, -> { by_name("Alive Status").active }

  scope :without_alive_status_type, -> { where(:type_name.ne => ALIVE_STATUS) }

  # embeds_many :external_service_responses  -> needs datamigration
  embeds_many :type_history_elements


  embeds_many :vlp_documents, as: :documentable do

    def uploaded
      @target.select{|document| document.identifier }
    end
  end

  def accept(visitor)
    visitor.visit(self)
  end

  def type_unverified?
    !type_verified?
  end

  def type_verified?
    SATISFIED_STATES.include? validation_status
  end

  def is_type_outstanding?
    OUTSTANDING_STATES.include?(validation_status)
  end

  def is_type_expired?
    validation_status == "expired"
  end

  def is_type_negative_response_received?
    validation_status == 'negative_response_received'
  end

  def outstanding_no_docs?
    is_type_outstanding? && vlp_documents.empty?
  end

  def unverified_no_docs?
    type_unverified? && vlp_documents.empty?
  end

  def add_type_history_element(params)
    type_history_elements << TypeHistoryElement.new(params)
  end

  def verif_due_date
    verification_document_due = EnrollRegistry[:verification_document_due_in_days].item
    due_date || TimeKeeper.date_of_record + verification_document_due.days
  end

  def move_type_to_curam
    update_attributes(:validation_status => "curam")
  end

  # This self_attestion status is only used for state Residency
  def attest_type
    update_attributes({validation_status: 'attested', update_reason: "Self Attest #{LOCATION_RESIDENCY}"})
  end

  def pass_type
    update_attributes(:validation_status => "verified")
  end

  def reject_type(reason_for_update)
    update_attributes!(validation_status: 'rejected', update_reason: reason_for_update, rejected: true)
  end

  def fail_type
    verification_document_due = EnrollRegistry[:verification_document_due_in_days].item
    status = if self.reload.validation_status == 'rejected'
               'rejected'
             else
               is_enrolled = person.families.any? { |family| family.person_has_an_active_enrollment?(person) }
               (is_enrolled ? 'outstanding' : 'negative_response_received')
             end
    attrs =
      if EnrollRegistry.feature_enabled?(:set_due_date_upon_response_from_hub)
        {:validation_status => status, :due_date => (TimeKeeper.date_of_record + verification_document_due.days), :due_date_type => 'response_from_hub'}
      else
        {:validation_status => status}
      end

    update_attributes(attrs)
  end

  def pending_type
    update_attributes(:validation_status => "pending")
  end

  def expire_type
    update_attributes(:validation_status => "expired", :update_reason => "Moved to Coverall")
  end

  def type_documents
    vlp_documents.select{|doc| doc.identifier.present?}
  end
end
