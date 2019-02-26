module ModelEvents
  module BrokerAgencyAccount

    REGISTERED_EVENTS = [
      :broker_hired,
      :broker_fired
    ]

    def notify_before_save

      if persisted? && changed? && changed_attributes.include?("is_active") && employer_profile.present?
        is_broker_fired = true
      end

      if !persisted? && valid? && employer_profile.present?
        is_broker_hired = true
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