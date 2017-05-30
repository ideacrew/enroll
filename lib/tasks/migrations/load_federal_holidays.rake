namespace :load_federal_holidays do
  desc "load federal holioday from xlsx file"
  task :update_federal_holidays => :environment do 
    begin
      ScheduledEvent.find_or_create_by!(
          type: 'holiday',
          event_name: 'Martin Luthor Bday',
          offset_rule: 0,
          start_time: nth_wday(3, 1, 1, Date.today.year)
          )
      ScheduledEvent.find_or_create_by!(
          type: 'holiday',
          event_name: 'Washington Bday',
          offset_rule: 0,
          start_time: nth_wday(3, 1, 2, Date.today.year)
          )
      ScheduledEvent.find_or_create_by!(
          type: 'holiday',
          event_name: 'Memorial Day',
          offset_rule: 0,
          start_time: last_monday_may(Date.today.year, 5, 31)
          )
      ScheduledEvent.find_or_create_by!(
          type: 'holiday',
          event_name: 'Labor Day',
          offset_rule: 0,
          start_time: nth_wday(1, 1, 9, Date.today.year)
          )
      ScheduledEvent.find_or_create_by!(
          type: 'holiday',
          event_name: 'Columbus Day',
          offset_rule: 0,
          start_time: nth_wday(2, 1, 10, Date.today.year)
          )
      ScheduledEvent.find_or_create_by!(
          type: 'holiday',
          event_name: 'Thanksgiving Day',
          offset_rule: 0,
          start_time: nth_wday(4, 4, 11, Date.today.year)
          )
      ScheduledEvent.find_or_create_by!(
          type: 'holiday',
          event_name: 'Veterans Day',
          offset_rule: 0,
          start_time: schedule_time(Date.new(Date.today.year, 11, 11))
          )
      ScheduledEvent.find_or_create_by!(
          type: 'holiday',
          event_name: 'New Year Day',
          offset_rule: 0,
          start_time: schedule_time(Date.new(Date.today.year, 01, 01))
          )
      ScheduledEvent.find_or_create_by!(
          type: 'holiday',
          event_name: 'Christmas Day',
          offset_rule: 0,
          start_time: schedule_time(Date.new(Date.today.year, 12, 25))
          )
      ScheduledEvent.find_or_create_by!(
          type: 'holiday',
          event_name: 'Independence Day',
          offset_rule: 0,
          start_time: schedule_time(Date.new(Date.today.year, 07, 04))
          )
    rescue => e
      puts e.inspect
    end
  end


  def nth_wday(n, wday, month, year)
    t = Time.local year, month, 1
    first = t.wday
    if first == wday
      fwd = 1
    elsif first < wday
      fwd = wday - first + 1
    elsif first > wday
      fwd = (wday+7) - first + 1
    end
    target = fwd + (n-1)*7
    begin
      t2 = Time.local year, month, target
    rescue ArgumentError
    return nil
    end
    if t2.mday == target
      t2
    else
      nil
    end
  end

  def last_monday_may(year, month, day)
    date = Date.new(year, month, day)
    date - ( date.wday - 1 )
  end

  def schedule_time(time)
    if time.saturday?
      return time.prev_month.end_of_month if time.day == 1
      return time = time - 1.day
    end
    if time.sunday?
      return time.next_month.beginning_of_month if time == time.end_of_month
      return time = time  + 1.day
    end
    return time
  end
end