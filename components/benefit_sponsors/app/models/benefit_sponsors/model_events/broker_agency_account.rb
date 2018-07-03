module BenefitSponsors
  module ModelEvents
    module BrokerAgencyAccount

      REGISTERED_EVENTS = [
        :broker_hired,
        :broker_fired
      ]

      def notify_on_save
        if !persisted? && valid?
          is_broker_hired = true
        end

        if persisted? && changed? && changed_attributes.include?("is_active")
          is_broker_fired = true
        end

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