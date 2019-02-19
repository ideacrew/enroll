module ModelEvents
  module GeneralAgencyAccount

    REGISTERED_EVENTS = [
      :general_agency_hired,
      :general_agency_fired
    ]

    def notify_before_save
      if changed? && changed_attributes.include?('aasm_state') && changed_attributes.include?('end_on') && employer_profile.present?
        is_general_agency_fired = true
      end

      if valid? && employer_profile.present? && changed_attributes.include?('broker_role_id') && changed_attributes.include?('start_on')
        is_general_agency_hired = true
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