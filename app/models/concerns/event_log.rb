# frozen_string_literal: true

# Event Log concern for storing events
module EventLog
  extend ActiveSupport::Concern
  include GlobalID::Identification

  included do
    # EVENT_CATEGORIES = %i[osse_eligibility password_change].freeze

    belongs_to :account, class_name: "User", inverse_of: :nil
    embeds_one :session_detail, class_name: "EventLog::SessionDetail", as: :sessionable

    # field :account_id, type: String
    field :subject_gid, type: String
    field :event_category, type: Symbol
    field :correlation_id, type: String
    field :host_id, type: String
    field :trigger, type: String
    field :message_id, type: String
    field :event_time, type: DateTime
    field :tags, type: Array

    index({ subject_gid: 1 })
    index({ event_category: 1 })
    index({ account_id: 1 })
    index({ host_id: 1 })
    index({ trigger: 1 })
    index({ event_time: 1 })

    scope :by_subject, ->(subject_id) { where(subject_gid: /#{subject_id}/i) }
    scope :by_event_category, ->(category) { where(event_category: category) }
    scope :by_account, ->(account_id) { where(account_id: account_id) }
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
