class VerificationType
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :person, polymorphic: true

  VALIDATION_STATES = %w(na valid outstanding pending)

  field :type_name, type: String
  field :validation_status, type: String
  field :applied_roles, type: Array, default: ["consumer_role"] #[consumer_role, resident_role, ...]
  field :update_reason, type: String
  field :rejected, type: Boolean
  field :external_service, type: String
  field :due_date, type: Date
  field :updated_by
  field :inactive, type: Boolean #use this field (assign true) only if type was present but for some reason if is not applicable anymore

  scope :active, -> {where(:inactive.ne => true )}

  # embeds_many :external_service_responses
  # embeds_many :verification_type_history_elements
end