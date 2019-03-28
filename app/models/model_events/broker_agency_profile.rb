module ModelEvents
  module BrokerAgencyProfile

    REGISTERED_EVENTS = [
      :default_general_agency_hired,
      :default_general_agency_fired
    ]

    def notify_before_save
      event_options = {}
      if changed? && valid? && changed_attributes.include?('default_general_agency_profile_id')
        if default_general_agency_profile_id.present?
          is_default_general_agency_hired = true
        else
          is_default_general_agency_fired = true
          event_options = { :old_general_agency_profile_id => changed_attributes["default_general_agency_profile_id"].to_s }
        end

        # This will be triggered when a broker with an existing default general agency selects a new one.
        if default_general_agency_profile_id.present? && changed_attributes["default_general_agency_profile_id"].present?
          is_default_general_agency_fired = true
          event_options = { :old_general_agency_profile_id => changed_attributes["default_general_agency_profile_id"].to_s }
        end
      end

      REGISTERED_EVENTS.each do |event|
        if event_fired = instance_eval("is_" + event.to_s)
          notify_observers(ModelEvent.new(event, self, event_options))
        end
      end
    end
  end
end