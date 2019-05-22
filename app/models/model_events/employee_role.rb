module ModelEvents
  module EmployeeRole

    REGISTERED_EVENTS = [
      :employee_matches_employer_roster
    ]

    def notify_on_create

      if self.present?
        is_employee_matches_employer_roster = true
      end

      REGISTERED_EVENTS.each do |event|
        if event_fired = instance_eval("is_" + event.to_s)
          event_options = {}
          notify_observers(ModelEvent.new(event, self, event_options))
        end
      end
    end
  end
end