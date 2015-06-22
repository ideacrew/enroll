class TimeKeeper
  include Singleton

  # time zone management
  # class << SYSTEM_TIME = Object.new

  def initialize
    @date_of_record = Date.current.beginning_of_day
    @mutex  = Mutex.new
  end

  def date_of_record=(new_date)
    with_mutex { @date_of_record = new_date.to_date.beginning_of_day }
  end

  def date_of_record
    with_mutex { @date_of_record }
    @date_of_record
  end

  def clear
    with_mutex { @date_of_record.clear }
  end

  def self.date_of_record=(new_date)
    new_date = new_date.to_date.beginning_of_day
    instance.date_of_record = new_date unless new_date == instance.date_of_record
    instance.date_of_record
  end

  def self.date_of_record
    instance.date_of_record
  end

  def self.clear
    instance.clear
  end

  def push_date_of_record
    EmployerProfile.advance_day(@date_of_record)
    Family.advance_day(@date_of_record)
    HbxProfile.advance_day(@date_of_record)
  end

private

  def with_mutex
    @mutex.synchronize { yield }
  end


#   def initialize(*args)
#     @settings ||= ConfigSetting.first()
#     if !@settings.nil?
#       @attributes = @settings.attributes
#       @settings   = super(@attributes)
#     else
#       @settings = super(*args)
#       self.save!
#     end
#     @settings
#   end
# end

#   class << self

#     def date_of_record=(new_date)
#       write_attribute(:date_of_record, new_date.to_date.beginning_of_day)
#     end
#   end

end
