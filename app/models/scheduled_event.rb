class ScheduledEvent
  include Mongoid::Document

  field :type, type: String
  field :event_name, type: String
  field :start_date, type: Date
  field :one_time, type: Boolean, default: false
  field :recurring_rules, type: String
  field :offset_rule, type: Integer, default: none

  validates_presence_of :type, :event_name, :one_time, :start_date
end