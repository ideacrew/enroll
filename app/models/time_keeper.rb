class TimeKeeper
  # include Singleton

  def initialize(*args)
    if current_date.nil?
    else
    end
  end

  def self.current_date
    Date.current
  end

  def set_model_dates
    EmployerProfile.advance_day(current_date)
    Family.advance_day(current_date)
    HbxProfile.advance_day(current_date)
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

#     def current_date=(new_date)
#       write_attribute(:current_date, new_date.to_date.beginning_of_day)
#     end
#   end

end
