# frozen_string_literal: true

# This module is a utility module that is used throughout the app to parse dates.
module ParseDateHelper
  # Parses a date string into a Date object.
  #
  # @param string [String] the date string to parse.
  # @return [Date, nil] the Date object, or nil if the string is blank.
  def parse_date(string)
    return nil if string.blank?
    date_format = string.match(/\d{4}-\d{2}-\d{2}/) ? "%Y-%m-%d" : "%m/%d/%Y"
    Date.strptime(string, date_format)
  end
end