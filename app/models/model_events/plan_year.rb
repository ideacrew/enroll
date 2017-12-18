module ModelEvents
  module PlanYear

    REGISTERED_EVENTS = [
      :renewal_application_created,
      :initial_application_submitted,
      :renewal_application_submitted,
      :renewal_application_autosubmitted,
      :ineligible_initial_application_submitted,
      :ineligible_renewal_application_submitted,
      :open_enrollment_began,
      :open_enrollment_ended,
      :application_denied,
      :renewal_application_denied
    ]

    def notify_on_save
      if aasm_state_changed?

        if is_transition_matching?(to: :renewing_draft, from: :draft)
          is_renewal_application_created = true
        end

        if is_transition_matching?(to: :publish_pending, from: :draft, event: [:publish, :force_publish])
          is_ineligible_initial_application_submitted = true
        end

        if is_transition_matching?(to: :renewing_publish_pending, from: :renewing_draft, event: [:publish, :force_publish])
          is_ineligible_renewal_application_submitted = true
        end

        if is_transition_matching?(to: [:published, :enrolling], from: :draft, event: :publish)
          is_initial_application_submitted = true
        end

        if is_transition_matching?(to: [:renewing_published, :renewing_enrolling], from: :renewing_draft, event: :publish)
          is_renewal_application_submitted = true
        end

        if is_transition_matching?(to: [:renewing_published, :renewing_enrolling], from: :renewing_draft, event: :force_publish)
          is_renewal_application_autosubmitted = true
        end

        if enrolling? || renewing_enrolling?
          is_open_enrollment_began = true
        end

        if enrolled? || renewing_enrolled?
          is_open_enrollment_ended = true
        end

        if is_transition_matching?(to: :application_ineligible, from: :enrolling, event: :advance_date)
          is_application_denied = true
        end

        if is_transition_matching?(to: :renewing_application_ineligible, from: :renewing_enrolling, event: :advance_date)
          is_renewal_application_denied = true
        end
      
        # TODO -- encapsulated notify_observers to recover from errors raised by any of the observers
        REGISTERED_EVENTS.each do |event|
          if event_fired = instance_eval("is_" + event.to_s)
            # event_name = ("on_" + event.to_s).to_sym
            event_options = {} # instance_eval(event.to_s + "_options") || {}
            notify_observers(ModelEvent.new(event, self, event_options))
          end
        end
      end
    end

    def is_transition_matching?(from: nil, to: nil, event: nil)
      aasm_matcher = lambda {|expected, current|
        expected.blank? || expected == current || (expected.is_a?(Array) && expected.include?(current))
      }

      current_event_name = aasm.current_event.to_s.gsub('!', '').to_sym
      aasm_matcher.call(from, aasm.from_state) && aasm_matcher.call(to, aasm.to_state) && aasm_matcher.call(event, current_event_name)
    end
  end
end