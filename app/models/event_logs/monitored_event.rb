# frozen_string_literal: true

module EventLogs
  class MonitoredEvent
    include Mongoid::Document
    include Mongoid::Timestamps

    belongs_to :monitorable, polymorphic: true

    field :market_kind, type: String
    field :account_id, type: String
    field :subject_hbx_id, type: String
    field :event_category, type: Symbol
    field :event_time, type: DateTime
    field :login_session_id, type: String
  end
end
