module BenefitSponsors
  module ModelEvents
    module BrokerAgencyAccount

      BROKER_HIRED_EVENTS = [
        :broker_hired_notice_to_broker,
        :broker_agency_hired_confirmation,
        :broker_hired_confirmation_to_employer
      ]

      BROKER_FIRED_EVENTS = [
        :broker_fired_confirmation_to_broker,
        :broker_agency_fired_confirmation,
        :broker_fired_confirmation_to_employer
      ]

      def notify_on_save
        if is_active_changed?
          is_active ? broker_hired_notices : broker_fired_notices
        end
      end

      def broker_hired_notices
        BROKER_HIRED_EVENTS.each do |event_name|
          notify_observers(ModelEvent.new(event_name, self, event_options = {}))
        end
      end

      def broker_fired_notices
        BROKER_FIRED_EVENTS.each do |event_name|
          notify_observers(ModelEvent.new(event_name, self, event_options = {}))
        end
      end

      # REGISTERED_EVENTS.each do |event|
      #   if event_fired = instance_eval("is_" + event.to_s)
      #     # event_name = ("on_" + event.to_s).to_sym
      #     event_options = {} # instance_eval(event.to_s + "_options") || {}
      #     notify_observers(ModelEvent.new(event, self, event_options))
      #   end
      # end
    end

  end
end