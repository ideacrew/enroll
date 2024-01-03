# frozen_string_literal: true

module EventLogs
  class MonitoredEvent
    include Mongoid::Document
    include Mongoid::Timestamps

    belongs_to :monitorable, polymorphic: true

    attr_accessor :outcome

    field :account_hbx_id, type: String
    field :account_username, type: String
    field :subject_hbx_id, type: String
    field :event_category, type: Symbol
    field :event_time, type: DateTime
    field :login_session_id, type: String

    index({ account_hbx_id: 1 })
    index({ account_username: 1 })
    index({ subject_hbx_id: 1 })
    index({ event_category: 1 })
    index({ event_time: 1 })
    index({ login_session_id: 1 })

    def self.get_category_options(subject_hbx_id = nil)
      if subject_hbx_id.present?
        where(subject_hbx_id: subject_hbx_id).pluck(:event_category).uniq
      else
        pluck(:event_category).uniq
      end
    end
  end
end
