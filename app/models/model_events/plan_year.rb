module ModelEvents
  module PlanYear

    STATE_CHANGE_EVENTS = [
      :application_renewed,
      :application_published,
      :application_pending,
      :open_enrolment_begin, 
      :open_enrolment_end,
      :application_rejected
    ]

    def notify_on_save
      if aasm_state_changed?

        if [:published, :enrolling, :renewing_published, :renewing_enrolling].include?(aasm_state.to_sym)
          is_application_published  = true
        end

        if enrolling? || renewing_enrolling?
          is_open_enrollment_begin = true
        end

        if enrolled? || renewing_enrolled?
          is_open_enrollment_end = true
        end

        if application_ineligible?
          is_application_rejected = true
        end

        if renewing_draft?
          is_application_renewed = true
        end

        if publish_pending?
          is_application_pending = true
        end

        # TODO -- encapsulated notify_observers to recover from errors raised by any of the observers
        STATE_CHANGE_EVENTS.each do |event|
          if event_fired = instance_eval("is_" + event.to_s)
            event_name = ("on_" + event.to_s).to_sym
            event_options = instance_eval(event.to_s + "_options") || {}
            notify_observers(event_name, self, event_options.merge(aasm: aasm))
          end
        end
      end
    end
  end
end