# frozen_string_literal: true

# Event Log concern for storing events
module EventLog
  extend ActiveSupport::Concern
  include GlobalID::Identification

  included do
    SEVERITY = %i[debug info notice warn error critical alert emerg].freeze
    LOG_LEVELS = %i[debug info warn error fatal unknown].freeze
    EVENT_CATEGORIES = %i[osse_eligibility password_change].freeze

    field :subject_gid, type: String
    field :correlation_id, type: String
    field :event_category, type: Symbol
    field :session_id, type: String # belongs_to :session or embed document?

    # convert this to association
    # belongs_to :account, class_name: "User", optional: false
    field :account_id, type: String # TODO: we should seed system account
    field :host_id, type: String

    field :trigger, type: String
    field :response, type: String
    field :log_level, type: Symbol
    field :severity, type: Symbol
    field :event_time, type: DateTime
    field :tags, type: Array

    index({ subject_gid: 1 })
    index({ event_category: 1 })
    index({ session_id: 1 })
    index({ account_id: 1 })
    index({ host_id: 1 })
    index({ trigger: 1 })
    index({ severity: 1 })
    index({ log_level: 1 })
    index({ event_time: 1 })

    scope :by_subject, ->(subject_id) { where(subject_gid: /#{subject_id}/i) }
    scope :by_event_category, ->(category) { where(event_category: category) }
    scope :by_session, ->(session_id) { where(session_id: session_id) }
    scope :by_account, ->(account_id) { where(account_id: account_id) }
    scope :by_log_level, ->(log_level) { where(log_level: log_level) }
    scope :by_severity, ->(severity) { where(severity: severity) }
    scope :by_host, ->(host_id) { where(host_id: host_id) }
    scope :by_trigger, ->(trigger) { where(trigger: trigger) }
    scope :events_during,
          lambda { |time_period|
            where(
              :event_time.gte => time_period.min,
              :event_time.lte => time_period.max
            )
          }
  end
end
