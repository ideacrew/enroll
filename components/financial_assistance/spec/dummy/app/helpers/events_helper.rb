# frozen_string_literal: true

# Helper for events.
module EventsHelper
  def simple_date_for(date_time)
    return nil if date_time.blank?
    date_time.strftime("%Y%m%d")
  end
end
