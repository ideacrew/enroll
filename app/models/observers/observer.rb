module Observers
  class Observer
    include Acapi::Notifiers

    def trigger_notice(recipient: recipient, event_object: event_object, notice_event: notice_event)
      resource_mapping = Notifier::ApplicationEventMapper.map_resource(recipient.class)
      event_name = Notifier::ApplicationEventMapper.map_event_name(resource_mapping, notice_event)
      notify(event_name, {
        resource_mapping.identifier_key => recipient.send(resource_mapping.identifier_method).to_s,
        :event_object_kind => event_object.class.to_s,
        :event_object_id => event_object.id.to_s
      })
    end
  end
end