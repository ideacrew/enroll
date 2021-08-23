class TimeKeeper
  include Config::AcaModelConcern
  include Mongoid::Document
  include Singleton
  include Acapi::Notifiers
  extend Acapi::Notifiers

  CACHE_KEY = "timekeeper/date_of_record"

  # time zone management

  def initialize
  end

  def self.local_time(a_time)
    a_time.in_time_zone("Eastern Time (US & Canada)")
  end

  def self.format_date(a_time)
    local_time(a_time).strftime('%m/%d/%Y')
  end

  def self.format_date_time(a_time)
    local_time(a_time).strftime('%m/%d/%Y %I:%M%p')
  end

  def self.exchange_zone
    "Eastern Time (US & Canada)"
  end

  def self.start_of_exchange_day_from_utc(date)
    start_of_day = date.beginning_of_day
    Time.use_zone(exchange_zone) do
      Time.zone.local(start_of_day.year, start_of_day.month, start_of_day.day, 0,0,0)
    end.utc
  end

  def self.end_of_exchange_day_from_utc(date)
    start_of_next_day = (date + 1.day).beginning_of_day
    Time.use_zone(exchange_zone) do
      Time.zone.local(start_of_next_day.year, start_of_next_day.month, start_of_next_day.day, 0,0,0)
    end.utc
  end

  def self.date_according_to_exchange_at(a_time)
    a_time.in_time_zone(exchange_zone).to_date
  end

  def self.set_date_of_record(new_date)
    new_date = new_date.to_date
    if instance.date_of_record != new_date
      if instance.date_of_record > new_date
        log("Attempt made to set date to past: #{new_date}", {:severity => :error})
        raise StandardError, "system may not go backward in time"
      else
        number_of_days = (new_date - instance.date_of_record).to_i
        number_of_days.times do
          instance.set_date_of_record(instance.date_of_record + 1.day)
          instance.push_date_of_record
          instance.push_date_change_event
        end
      end
    end
    instance.date_of_record
  end

  # DO NOT EVER USE OUTSIDE OF TESTS
  def self.set_date_of_record_unprotected!(new_date)
    new_date = new_date.to_date
    if instance.date_of_record != new_date
      (new_date - instance.date_of_record).to_i
      instance.set_date_of_record(new_date)
    end
    instance.date_of_record
  end

  def self.date_of_record
    instance.date_of_record
  end

  def self.datetime_of_record
    instant = Time.current
    instance.date_of_record.to_datetime + instant.hour.hours + instant.min.minutes + instant.sec.seconds
  end

  def set_date_of_record(new_date)
    Rails.cache.write(CACHE_KEY, new_date.strftime("%Y-%m-%d"))
  end

  def date_of_record
    tl_value = thread_local_date_of_record
    return tl_value unless tl_value.blank?
    found_value = Rails.cache.fetch(CACHE_KEY) do
      log("date_of_record not available for TimeKeeper - using Date.current")
      Date.current.strftime("%Y-%m-%d")
    end
    Date.strptime(found_value, "%Y-%m-%d")
  end

  def push_date_of_record
    notify_logger("TimeKeeper advance day started at #{Time.now.in_time_zone('Eastern Time (US & Canada)').strftime('%m-%d-%Y %H:%M:%S')}")
    FinancialAssistance::Application.advance_day(self.date_of_record)
    BenefitSponsorship.advance_day(self.date_of_record)
    BenefitSponsors::ScheduledEvents::AcaShopScheduledEvents.advance_day(self.date_of_record)
    # EmployerProfile.advance_day(self.date_of_record)
    Family.advance_day(self.date_of_record) if individual_market_is_enabled?
    HbxEnrollment.advance_day(self.date_of_record)
    CensusEmployee.advance_day(self.date_of_record)
    ConsumerRole.advance_day(self.date_of_record)
    QualifyingLifeEventKind.advance_day(self.date_of_record)
    notify_logger("TimeKeeper advance day ended at #{Time.now.in_time_zone('Eastern Time (US & Canada)').strftime('%m-%d-%Y %H:%M:%S')}")
  end

  def push_date_change_event
    begin
      BenefitSponsors::BenefitApplications::BenefitApplication.date_change_event(self.date_of_record)
    rescue Exception => e
      Rails.logger.error { "Couldn't trigger benefit application date change events due to #{e.inspect}" }
    end
  end

  def notify_logger(message)
    Rails.logger.info(message)
    log(message)
  end

  def self.with_cache
    Thread.current[:time_keeper_local_cached_date] = date_of_record
    yield
    Thread.current[:time_keeper_local_cached_date] = nil
  end

  def thread_local_date_of_record
    Thread.current[:time_keeper_local_cached_date]
  end
end
