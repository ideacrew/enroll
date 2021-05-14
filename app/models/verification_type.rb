class VerificationType
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::History::Trackable

  embedded_in :person

  LOCATION_RESIDENCY = EnrollRegistry[:enroll_app].setting(:state_residency).item
  ALL_VERIFICATION_TYPES = [LOCATION_RESIDENCY, "Social Security Number", "American Indian Status", "Citizenship", "Immigration status"].freeze
  NON_CITIZEN_IMMIGRATION_TYPES = [LOCATION_RESIDENCY, "Social Security Number", "American Indian Status"].freeze
  VALIDATION_STATES = %w[na unverified pending review outstanding verified attested expired curam].freeze
  OUTSTANDING_STATES = %w[outstanding].freeze
  DUE_DATE_STATES = %w[review outstanding].freeze

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

  # embeds_many :external_service_responses  -> needs datamigration
  embeds_many :type_history_elements


  embeds_many :vlp_documents, as: :documentable do

    def uploaded
      @target.select{|document| document.identifier }
    end
  end

<<<<<<< HEAD
<<<<<<< HEAD
=======
  # TODO: Temporary until we figure out the downstreams of refatoring this
  def localize_residency
    return type_name unless type_name == 'DC Residency'
    state_abbreviation = EnrollRegistry[:enroll_app].setting(:state_abbreviation).item
    "#{state_abbreviation} Residency"
  end

>>>>>>> 97df31a508... REFS - Maintenance - Refactors verification to not hardcode dc residency.
=======
>>>>>>> f16d40a238... REFS Maintenance - Refactors residency as enroll registry.
  def type_unverified?
    !type_verified?
  end

  def type_verified?
    ["verified", "attested", "valid", "curam"].include? validation_status
  end

  def is_type_outstanding?
    validation_status == "outstanding"
  end

  def is_type_expired?
    validation_status == "expired"
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
    due_date || TimeKeeper.date_of_record + 95.days
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

  def fail_type
    update_attributes(:validation_status => "outstanding")
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
