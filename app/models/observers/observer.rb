module Observers
  class Observer
    include Acapi::Notifiers

    EVENT_PREFIX = "acapi.info.events."

    def trigger_notice(receipient, notice_event)
      resource_mapping = ApplicationEventMapper.map_resource(receipient.class)
      event_name = ApplicationEventMapper.map_event_name(resource_mapping, notice_event)
      notify(event_name, {resource_mapping.identifier_key => receipient.send(resource_mapping.identifier_method).to_s})
    end
  end
end