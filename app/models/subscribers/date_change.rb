module Subscribers
  class DateChange
    def self.subscription_details
        ["acapi.info.events.calendar.date_change"]
    end

    def call(event_name, e_start, e_end, msg_id, payload)
      stringed_key_payload = payload.stringify_keys
      current_date_string = stringed_key_payload.get("current_date")
      new_date = Date.parse(current_date_string, "%Y-%m-%d")
      Timekeeper.set_date_of_record
    end
  end
end
