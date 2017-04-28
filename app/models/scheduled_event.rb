class ScheduledEvent
  include Mongoid::Document

  field :type, type: String
  field :event_name, type: String
  field :start_date, type: Date
  field :one_time, type: Boolean, default: false
  field :recurring_rules, type: String
  field :offset_rule, type: Integer, default: none

  validates_presence_of :type, :event_name, :one_time

  EVENT_TYPES = %W(holiday system_event)
  HOLIDAYS = %W(New_Year Christmas)
  SYSTEMS_EVENTS = %W(Binder_Payment_due_Date Publish_Due_Date_Of_Month)
end