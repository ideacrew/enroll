class ShopNoticesNotifierJob < ActiveJob::Base
  queue_as :default

  def perform(recipient, event_object, notice_event)
    Resque.logger.level = Logger::DEBUG

    resource   = Notifier::ApplicationEventMapper.map_resource(recipient.class)
    event_kind = ApplicationEventKind.where(event_name: notice_event, resource_name: resource.resource_name.to_s).first

    if event_kind.present?
      notice_trigger = event_kind.notice_triggers.first

      builder = notice_trigger.notice_builder.camelize.constantize.new(recipient, {
        template: notice_trigger.notice_template,
        subject: event_kind.title,
        event_name: notice_event,
        options: build_options(event_object),
        mpi_indicator: notice_trigger.mpi_indicator,
        }.merge(notice_trigger.notice_trigger_element_group.notice_peferences)).deliver
    end
  end

  def build_options(event_object)
    {}
  end
end
