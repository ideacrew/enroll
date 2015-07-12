class TimeKeeper
  include Mongoid::Document
  include Singleton

  field :date_of_record, type: Date

  # time zone management

  def initialize
    @mutex  = Mutex.new
    @date_of_record = Date.current
  end

  def self.set_date_of_record(new_date)
    new_date = new_date.to_date
    if instance.date_of_record != new_date
      if instance.date_of_record > new_date
        raise StandardError, "system may not go backward in time"
      else
        number_of_days = (new_date - instance.date_of_record).to_i
        number_of_days.times do
          instance.set_date_of_record(instance.date_of_record + 1.day)
          instance.push_date_of_record
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

  def set_date_of_record(new_date)
    with_mutex { @date_of_record = new_date }
  end

  def date_of_record
    with_mutex { @date_of_record }
  end

  def push_date_of_record
    EmployerProfile.advance_day(@date_of_record)
    Family.advance_day(@date_of_record)
    #HbxProfile.advance_day(@date_of_record)
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

end
