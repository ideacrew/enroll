class ScheduledEvent
  include Mongoid::Document

  field :type, type: String
  field :event_name, type: String
  field :one_time, type: Boolean, default: false
  field :recurring_rules. type: String
  field :offset_rule, type: String, default: none

  validates_presence_of :type, :name, :one_time
end