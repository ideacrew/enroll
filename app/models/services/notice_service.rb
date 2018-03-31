module Services
  class NoticeService
    include Acapi::Notifiers

    attr_accessor :legacy_triggers

    def deliver(*args)
      if can_be_proccessed_as_legacy?(args[:recipient], args[:event_name])
        create_notice_job(args)
      else
        trigger_notice_event(args)
      end
    end

    def create_notice_job(*args)
      ShopNoticesNotifierJob.perform_later(args[:recipient].id.to_s, args[:event_name])
    end

    def trigger_notice_event(*args)
      resource = Notifier::ApplicationEventMapper.map_resource(args[:recipient].class)
      event_name = Notifier::ApplicationEventMapper.map_event_name(resource, args[:notice_event])
      notify(event_name, {
        resource.identifier_key => recipient.send(resource.identifier_method).to_s,
        :event_object_kind => args[:event_object].class.to_s,
        :event_object_id => args[:event_object].id.to_s
        })
    end

    def can_be_proccessed_as_legacy?(recipient, event_name)
      resource = Notifier::ApplicationEventMapper.map_resource(args[:recipient].class)
      ApplicationEventKind.where(event_name: notice_event, resource_name: resource.resource_name.to_s).present?
    end
  end
end