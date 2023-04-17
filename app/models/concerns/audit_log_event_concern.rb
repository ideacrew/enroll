# frozen_string_literal: true

# module provides audit log helper methods for models
module AuditLogEventConcern
  extend ActiveSupport::Concern

  class_methods do
    def audit_log_events_during(time_period)
      raise 'time range expected' unless time_period.is_a?(Range)

      audit_log_events.events_during(time_period)
    end

    def audit_log_events
      AuditLogEvent.by_subject("gid://#{GlobalID.app}/#{name}/")
    end
  end

  def audit_log_events_during(time_period)
    raise 'time range expected' unless time_period.is_a?(Range)

    audit_log_events.events_during(time_period)
  end

  def audit_log_events
    AuditLogEvent.by_subject(self.to_global_id.to_s)
  end
end
