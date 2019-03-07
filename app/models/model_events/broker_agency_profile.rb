module ModelEvents
  module BrokerAgencyProfile

    REGISTERED_EVENTS = [
      :general_agency_hired,
      :general_agency_fired
    ]

    def notify_on_save
      if changed? && changed_attributes.include?('default_general_agency_profile_id')
        if default_general_agency_profile_id.present?
          is_general_agency_hired = true
        else
          is_general_agency_fired = true
        end
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