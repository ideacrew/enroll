String.class_eval do
  def to_digits
    self.gsub(/\D/, '')
  end

  def to_date_safe
    date = nil
    unless self.blank?
      date_pattern = nil
      case
      when self.match(/^\d{1,2}\/\d{1,2}\/\d{2}$/) # "5/1/15", "05/01/15"
        date_pattern = "%m/%d/%y"
      when self.match(/^\d{1,2}\/\d{1,2}\/\d{4}$/) # "5/1/2015", "05/01/2015"
        date_pattern = "%m/%d/%Y"
      end

      begin
        if date_pattern.nil?
          date = Date.parse(self)
        else
          date = Date.strptime(self, date_pattern)
        end
      rescue Exception => e
        # puts "There was an error parsing {#{self}} as a date."
      end
    end
    date
  end
end

Object.class_eval do
  def to_digits
    self.to_s.to_digits
  end

  def to_date_safe
    self.to_s.to_date_safe
  end
end
