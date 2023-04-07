class AuditLogEvent
  include Mongoid::Document
  include Mongoid::Timestamps
  include GlobalID::Identification

  SEVERITY = %i(debug info notice warn error critical alert emerg)
  LOG_LEVELS = %i(debug info warn error fatal unknown)
  EVENT_CATEGORIES = %i(osse_eligibility password_change)

  field :subject_gid, type: String
  field :correlation_id, type: String
  field :event_category, type: Symbol

  field :session_id, type: String
  field :account_id, type: String # covert this to belongs_to association once account model introduced
  field :host_id, type: String

  field :trigger, type: String
  field :response, type: String
  field :log_level, type: Symbol
  field :severity, type: Symbol
  field :event_time, type: DateTime
  field :tags, type: Array

  index({subject_id: 1})
  index({event_category: 1})
  index({session_id: 1})
  index({account_id: 1})
  index({host_id: 1})
  index({trigger: 1})

  index({event_time: 1}, {account_id: 1})
end
