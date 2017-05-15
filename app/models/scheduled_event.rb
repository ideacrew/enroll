class ScheduledEvent
  include Mongoid::Document
  include Mongoid::Timestamps
  include ScheduledEventService

  field :type, type: String
  field :event_name, type: String
  field :start_time, type: Date
  field :one_time, type: Boolean, default: true
  field :recurring_rules, type: Hash
  field :offset_rule, type: Integer, default: 0

<<<<<<< HEAD
  embeds_many :event_exceptions
=======
  validates_presence_of :type, :event_name, :one_time, :start_time, :offset_rule
>>>>>>> minor issues

  validates_presence_of :type, :event_name, :one_time, :start_time, :message => "fields type, event_name can't be empty"

  EVENT_TYPES = %W(system holiday)
  HOLIDAYS = %W(new_year martinluthor_birthdday washingtons_day memorial_day independence_day
                Labour_day columbus_day veterans_day Christmas Thanksgiving_day)
  SYSTEM_EVENTS = %W(binder_payment_due_date publish_due_date_of_month ivl_monthly_open_enrollment_due_on shop_initial_application_publish_due_day_of_month shop_renewal_application_monthly_open_enrollment_end_on
                       shop_renewal_application_publish_due_day_of_month shop_renewal_application_force_publish_day_of_month shop_open_enrollment_monthly_end_on shop_group_file_new_enrollment_transmit_on
                       shop_group_file_update_transmit_day_of_week)

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
<<<<<<< HEAD
    event_exceptions.each do |exception|
      schedule.add_exception_time(exception.time)
    end
=======

>>>>>>> minor issues
    schedule
  end

  def calendar_events(start)
    if recurring_rules.blank?
      [self]
    else
<<<<<<< HEAD
=======
      #start_date = start.beginning_of_month.beginning_of_week
>>>>>>> fix prev and next links
      end_date = start.end_of_year.end_of_month.end_of_week
      schedule(start_time).occurrences(end_date).map do |val|
        ScheduledEvent.new(id: id, event_name: event_name, start_time: val)
      end
    end
  end

  def self.day_of_month_for(event_name)
    begin
      ScheduledEvent.find_by!(event_name: event_name).start_time.day
    rescue Mongoid::Errors::DocumentNotFound
      nil
    end
  end
end
