class ScheduledEvent
  include Mongoid::Document
  include Mongoid::Timestamps

  field :type, type: String
  field :event_name, type: String
  field :start_time, type: Date
  field :one_time, type: Boolean, default: true
  field :recurring_rules, type: Hash
  field :offset_rule, type: Integer, default: none

  validates_presence_of :type, :event_name, :one_time, :start_time, :offset_rule

  EVENT_TYPES = %W(holiday system_event)
  HOLIDAYS = %W(New_Year MartinLuthor_bday washingtons_day memorial_day independence_day Labour_day columbus_day veterans_day Christmas Thanksgiving_day)
  SYSTEMS_EVENTS = %W(Binder_Payment_due_Date Publish_Due_Date_Of_Month )

  def recurring_rules=(value)
    if RecurringSelect.is_valid_rule?(value)
      super(RecurringSelect.dirty_hash_to_rule(value).to_hash)
    else
      super(nil)
    end
  end

  def start_time=(value)
    if value.blank?
      super(TimeKeeper.date_of_record)
    else
      super(value.to_date) rescue super(Date.strptime(value, "%m/%d/%Y").to_date)
    end
  end

  def rule
    IceCube::Rule.from_hash recurring_rules
  end

  def schedule(start)
    schedule = IceCube::Schedule.new(start)
    schedule.add_recurrence_rule(rule)

    schedule
  end

  def calendar_events(start)
    if recurring_rules.blank?
      [self]
    else
      #start_date = start.beginning_of_month.beginning_of_week
      end_date = start.end_of_year.end_of_month.end_of_week
      schedule(start_time).occurrences(end_date).map do |val|
        ScheduledEvent.new(id: id, event_name: event_name, start_time: val)
      end
    end
  end
end