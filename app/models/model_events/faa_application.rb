module ModelEvents
  module FaaApplication

    REGISTERED_EVENTS = [
      :ineligibility_notice,
      :eligibility_notice
    ]

    def notify_on_save
      if aasm_state_changed?

        if aasm_state_was? == "submitted" && aasm_state == "determined"
          if is_family_totally_ineligibile
            is_ineligibility_notice = true
          else
            is_eligibility_notice = true
          end
        end

        # TODO: -- encapsulated notify_observers to recover from errors raised by any of the observers
        REGISTERED_EVENTS.each do |event|
          if event_fired = instance_eval("is_" + event.to_s)
            # event_name = ("on_" + event.to_s).to_sym
            event_options = {} # instance_eval(event.to_s + "_options") || {}
            notify_observers(ModelEvent.new(event, self, event_options))
          end
        end
      end
    end
  end
end
